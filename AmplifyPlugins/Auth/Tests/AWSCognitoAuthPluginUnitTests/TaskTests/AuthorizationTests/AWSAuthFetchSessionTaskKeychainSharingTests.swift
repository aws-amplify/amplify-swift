//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@_spi(KeychainStore) import AWSPluginsCore

/// Verifies that when a shared keychain access group is enabled, the
/// fetchAuthSession reconcile path does not destroy locally-originated
/// in-flight sign-in/sign-out work, and only reconfigures when the
/// shared keychain genuinely diverges from the in-memory state machine.
class AWSAuthFetchSessionTaskKeychainSharingTests: XCTestCase {

    private actor StateRecorder {
        private(set) var seenStateTypes: Set<String> = []

        func record(_ type: String) {
            seenStateTypes.insert(type)
        }

        func observed(_ type: String) -> Bool {
            seenStateTypes.contains(type)
        }
    }

    private struct StubCredentialStore: CredentialStoreStateBehavior {
        let remote: AmplifyCredentials?

        func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
            switch type {
            case .amplifyCredentials:
                guard let remote else { throw KeychainStoreError.itemNotFound }
                return .amplifyCredentials(remote)
            case .deviceMetadata(let username):
                return .deviceMetadata(.noData, username)
            case .asfDeviceId(let username):
                return .asfDeviceId("", username)
            }
        }

        func storeData(data: CredentialStoreData) async throws { }
        func deleteData(type: CredentialStoreDataType) async throws { }
    }

    private func makeEnvironment(remote: AmplifyCredentials?) -> AuthEnvironment {
        let baseEnv = Defaults.makeDefaultAuthEnvironment()
        return AuthEnvironment(
            configuration: baseEnv.configuration,
            userPoolConfigData: baseEnv.userPoolConfigData,
            identityPoolConfigData: baseEnv.identityPoolConfigData,
            authenticationEnvironment: baseEnv.authenticationEnvironment,
            authorizationEnvironment: baseEnv.authorizationEnvironment,
            credentialsClient: StubCredentialStore(remote: remote),
            logger: baseEnv.logger
        )
    }

    private func runReconcile(initial: AuthState, remote: AmplifyCredentials?) async -> StateRecorder {
        let environment = makeEnvironment(remote: remote)
        let stateMachine = AuthStateMachine(
            resolver: AuthState.Resolver(),
            environment: environment,
            initialState: initial
        )
        let recorder = StateRecorder()
        let stream = await stateMachine.listen()
        let listener = Task {
            for await state in stream {
                await recorder.record(state.type)
            }
        }

        let task = AWSAuthFetchSessionTask(
            AuthFetchSessionRequest(options: AuthFetchSessionRequest.Options()),
            authStateMachine: stateMachine,
            configuration: Defaults.makeDefaultAuthConfigData(),
            environment: environment,
            isKeychainSharingEnabled: true
        )
        await task.reconcileWithSharedKeychainIfNeeded()

        // Allow the listener task one tick to drain queued state changes
        try? await Task.sleep(nanoseconds: 50_000_000)
        listener.cancel()
        return recorder
    }

    private func makeWaitingForCustomChallengeState() -> SignInState {
        let challenge = RespondToAuthChallenge.testData(challenge: .customChallenge)
        let method = SignInMethod.apiBased(.customWithoutSRP)
        return SignInState.resolvingChallenge(
            .waitingForAnswer(challenge, method, .confirmSignInWithCustomChallenge(nil)),
            .customChallenge,
            method
        )
    }

    // MARK: - Tests

    /// Given: state machine is `.signingIn(.resolvingChallenge(.waitingForAnswer))`,
    ///        remote keychain has no signed-in credentials.
    /// Then:  reconcile defers — state machine never transitions to `.configuringAuth`.
    func testInflightSigningInWithRemoteSignedOut_doesNotReconfigure() async {
        let initial = AuthState.configured(
            .signingIn(makeWaitingForCustomChallengeState()),
            .configured,
            .notStarted
        )

        let recorder = await runReconcile(initial: initial, remote: .noCredentials)
        let observed = await recorder.observed("AuthState.configuringAuth")
        XCTAssertFalse(
            observed,
            "Reconfigure must not run while sign-in is in flight and remote is signed out"
        )
    }

    /// Given: state machine is `.signingIn(...)`, remote keychain has fresh
    ///        signed-in user-pool credentials (sibling app signed in).
    /// Then:  reconcile adopts — state machine transitions through
    ///        `.configuringAuth`.
    func testInflightSigningInWithRemoteSignedIn_adoptsViaReconfigure() async {
        let initial = AuthState.configured(
            .signingIn(makeWaitingForCustomChallengeState()),
            .configured,
            .notStarted
        )

        let recorder = await runReconcile(initial: initial, remote: AmplifyCredentials.testData)
        let observed = await recorder.observed("AuthState.configuringAuth")
        XCTAssertTrue(
            observed,
            "Reconfigure must run to adopt remote sign-in mid-flow"
        )
    }

    /// Given: state machine is `.signedIn`, remote keychain matches local
    ///        (no sibling activity).
    /// Then:  reconcile is a no-op.
    func testQuiescentSignedInWithMatchingRemote_doesNotReconfigure() async {
        // Capture once — `AmplifyCredentials.testData` and `SignedInData.testData`
        // generate fresh `Date()` values on each access, so reading them twice
        // yields !=.
        let credentials = AmplifyCredentials.testData
        let signedInData: SignedInData
        if case .userPoolAndIdentityPool(let data, _, _) = credentials {
            signedInData = data
        } else {
            XCTFail("testData should be userPoolAndIdentityPool")
            return
        }
        let initial = AuthState.configured(
            .signedIn(signedInData),
            .sessionEstablished(credentials),
            .notStarted
        )

        let recorder = await runReconcile(initial: initial, remote: credentials)
        let observed = await recorder.observed("AuthState.configuringAuth")
        XCTAssertFalse(
            observed,
            "Reconfigure must not run when remote already matches local state"
        )
    }

    /// Given: state machine is `.signedIn`, remote keychain is `.noCredentials`
    ///        (sibling signed the user out).
    /// Then:  reconcile runs — sibling sign-out is picked up.
    func testQuiescentSignedInWithRemoteSignedOut_reconfigures() async {
        let initial = AuthState.configured(
            .signedIn(.testData),
            .sessionEstablished(.testData),
            .notStarted
        )

        let recorder = await runReconcile(initial: initial, remote: .noCredentials)
        let observed = await recorder.observed("AuthState.configuringAuth")
        XCTAssertTrue(
            observed,
            "Reconfigure must run when remote diverges from a quiescent signed-in state"
        )
    }

    /// Given: state machine is `.signingOut`, remote keychain mismatches.
    /// Then:  reconcile defers — sign-out side effects must run to completion.
    func testInflightSigningOut_doesNotReconfigure() async {
        let initial = AuthState.configured(
            .signingOut(.notStarted),
            .signingOut(AmplifyCredentials.testData),
            .notStarted
        )

        let recorder = await runReconcile(initial: initial, remote: .noCredentials)
        let observed = await recorder.observed("AuthState.configuringAuth")
        XCTAssertFalse(
            observed,
            "Reconfigure must not run while sign-out is in flight"
        )
    }
}
