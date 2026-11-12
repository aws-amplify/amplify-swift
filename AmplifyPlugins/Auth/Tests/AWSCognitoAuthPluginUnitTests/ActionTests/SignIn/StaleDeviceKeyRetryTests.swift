//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The sign-in actions that send a device key to Cognito in their first request drop a key Cognito no longer knows
/// (the device was forgotten, and `forgetDevice` keeps the local record) and send the request once more without it,
/// as the SRP flow's password verifier does.
final class StaleDeviceKeyRetryTests: XCTestCase {

    private let staleDevice = DeviceMetadata.metadata(.init(deviceKey: "stale-key", deviceGroupKey: "group", deviceSecret: "secret"))

    /// - Given: Cognito refusing any request that carries a device key with `ResourceNotFoundException` ("Device does
    ///   not exist."), and each of the password (`USER_PASSWORD_AUTH`), password-in-`USER_AUTH`, `USER_AUTH`, custom
    ///   and auto sign-in actions holding the stale device key
    /// - When: each action runs
    /// - Then:
    ///    - it sends its request twice, the first with the stale key and the second with none, and dispatches the
    ///      second's outcome, not an error
    ///    - it removes alice's device record, once
    func testEachFlowRetriesOnceWithoutAStaleDeviceKey() async throws {
        for (name, flow) in flows {
            let requests = DeviceKeyRecorder()
            let removals = DeviceRecordRemovals()
            let environment = Self.environment(removals) {
                Self.userPool(requests, refusingOnlyDeviceKeys: true)
            }

            let events = await run(flow, environment)

            XCTAssertEqual(requests.deviceKeys, ["stale-key", nil], name)
            XCTAssertFalse(events.contains(where: Self.isAuthError), "\(name): \(events)")
            XCTAssertEqual(removals.usernames, ["alice"], name)
        }
    }

    /// On an alias pool, the password answer in `USER_AUTH` removes the device record under the name the user typed,
    /// the one it was read with, not Cognito's echoed username. The challenge here holds two different names to guard
    /// that choice; no engine path builds such a challenge for this action today.
    ///
    /// - Given: a `USER_AUTH` password challenge whose username is Cognito's echo, a sub-like ID, and whose input
    ///   username is the email the user typed; Cognito refusing the stale device key
    /// - When: the password answer is sent
    /// - Then:
    ///    - the retry sends no device key, and the device record removed is the email's
    func testThePasswordAnswerOnAnAliasPoolRemovesTheRecordItWasReadWith() async throws {
        let requests = DeviceKeyRecorder()
        let removals = DeviceRecordRemovals()
        let environment = Self.environment(removals) {
            Self.userPool(requests, refusingOnlyDeviceKeys: true)
        }
        let sub = "4213df5e-f70b-4405-b8b4-963324a6e0b8"
        let action = InitiateMigrateAuth(
            username: sub,
            password: "password",
            clientMetadata: [:],
            deviceMetadata: staleDevice,
            respondToAuthChallenge: RespondToAuthChallenge(
                challenge: .password,
                availableChallenges: [],
                username: sub,
                session: "session",
                parameters: [:],
                inputUsername: "alice@example.com"
            )
        )

        let events = DispatchedEvents()
        await action.execute(withDispatcher: MockDispatcher { events.record($0) }, environment: environment)

        XCTAssertEqual(requests.deviceKeys, ["stale-key", nil])
        XCTAssertEqual(removals.usernames, ["alice@example.com"])
        XCTAssertFalse(events.events.contains(where: Self.isAuthError), "\(events.events)")
    }

    /// - Given: Cognito refusing every request with `ResourceNotFoundException`, and each action holding the stale
    ///   device key, then holding none
    /// - When: each action runs
    /// - Then:
    ///    - with the stale key it retries only once, then dispatches the error; with no key it sends one request and
    ///      dispatches the error: a `ResourceNotFoundException` without a device key is not about a device
    func testTheRetryHappensOnceAndOnlyForASentDeviceKey() async throws {
        for (name, flow) in flows {
            for device in [staleDevice, .noData] {
                let requests = DeviceKeyRecorder()
                let environment = Defaults.makeDefaultAuthEnvironment(userPoolFactory: {
                    Self.userPool(requests, refusingOnlyDeviceKeys: false)
                })

                let events = await run(flow, environment, device: device)

                let expected: [String?]
                if case .metadata = device {
                    expected = ["stale-key", nil]
                } else {
                    expected = [nil]
                }
                XCTAssertEqual(requests.deviceKeys, expected, name)
                XCTAssertTrue(events.contains(where: Self.isAuthError), "\(name): \(events)")
            }
        }
    }

    /// Auto sign-in's retry sends the sign-up's one-time session again. When Cognito refuses it there, the auto sign-in
    /// ends with that error.
    ///
    /// - Given: an auto sign-in holding the stale device key and the sign-up's session; Cognito refusing the stale key
    ///   with `ResourceNotFoundException`, then the session with `NotAuthorizedException` ("Invalid session for the
    ///   user.")
    /// - When: the auto sign-in runs
    /// - Then:
    ///    - it sends two requests with the sign-up's session, the first with the stale key and the second with none
    ///    - it dispatches one event, the `NotAuthorizedException` as a service error
    ///    - it removes alice's device record, once
    func testAnAutoSignInWhoseRetryIsRefusedEndsWithTheError() async throws {
        let requests = DeviceKeyRecorder()
        let sessions = DeviceKeyRecorder()
        let removals = DeviceRecordRemovals()
        let environment = Self.environment(removals) {
            MockIdentityProvider(mockInitiateAuthResponse: { input in
                requests.record(input.authParameters?["DEVICE_KEY"])
                sessions.record(input.session)
                if input.authParameters?["DEVICE_KEY"] != nil {
                    throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
                }
                throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user.")
            })
        }

        let events = await run({ AutoSignIn(signInEventData: Self.autoSignInData, deviceMetadata: $0) }, environment)

        XCTAssertEqual(requests.deviceKeys, ["stale-key", nil])
        XCTAssertEqual(sessions.deviceKeys, ["sign-up-session", "sign-up-session"])
        XCTAssertEqual(removals.usernames, ["alice"])
        XCTAssertEqual(events.count, 1, "\(events)")
        guard let event = events.first as? SignInEvent,
              case .throwAuthError(.service(let error)) = event.eventType else {
            return XCTFail("expected a service error, got \(events)")
        }
        XCTAssertTrue(error is AWSCognitoIdentityProvider.NotAuthorizedException, "\(error)")
    }

    // MARK: Helpers

    /// What a sign-up that completes with auto sign-in leaves for alice: `USER_AUTH` with the sign-up's session.
    private static let autoSignInData = SignInEventData(
        username: "alice",
        password: nil,
        signInMethod: .apiBased(.userAuth(preferredFirstFactor: nil)),
        session: "sign-up-session"
    )

    private typealias Flow = @Sendable (DeviceMetadata) -> any Action

    private var flows: [(String, Flow)] {
        [
            ("password", { device in
                InitiateMigrateAuth(username: "alice", password: "password", clientMetadata: [:], deviceMetadata: device, respondToAuthChallenge: nil)
            }),
            ("password in USER_AUTH", { device in
                InitiateMigrateAuth(
                    username: "alice",
                    password: "password",
                    clientMetadata: [:],
                    deviceMetadata: device,
                    respondToAuthChallenge: RespondToAuthChallenge(
                        challenge: .password,
                        availableChallenges: [],
                        username: "alice",
                        session: "session",
                        parameters: [:]
                    )
                )
            }),
            ("USER_AUTH", { device in
                InitiateUserAuth(
                    signInEventData: SignInEventData(username: "alice", password: nil, signInMethod: .apiBased(.userAuth(preferredFirstFactor: nil))),
                    deviceMetadata: device
                )
            }),
            ("custom", { device in
                InitiateCustomAuth(username: "alice", clientMetadata: [:], deviceMetadata: device)
            }),
            ("auto sign-in", { device in
                AutoSignIn(signInEventData: Self.autoSignInData, deviceMetadata: device)
            })
        ]
    }

    private func run(_ flow: Flow, _ environment: AuthEnvironment, device: DeviceMetadata? = nil) async -> [StateMachineEvent] {
        let events = DispatchedEvents()
        await flow(device ?? staleDevice).execute(withDispatcher: MockDispatcher { events.record($0) }, environment: environment)
        return events.events
    }

    /// The default auth environment over `userPool`, with a credential store that records each device-record removal.
    private static func environment(
        _ removals: DeviceRecordRemovals,
        userPool: @escaping @Sendable () throws -> CognitoUserPoolBehavior
    ) -> AuthEnvironment {
        let base = Defaults.makeDefaultAuthEnvironment(userPoolFactory: userPool)
        return AuthEnvironment(
            configuration: base.configuration,
            userPoolConfigData: base.userPoolConfigData,
            identityPoolConfigData: base.identityPoolConfigData,
            authenticationEnvironment: base.authenticationEnvironment,
            authorizationEnvironment: base.authorizationEnvironment,
            credentialsClient: RecordingCredentialStore(base: base.credentialsClient, removals: removals),
            logger: base.logger
        )
    }

    private static func isAuthError(_ event: StateMachineEvent) -> Bool {
        guard let event = event as? SignInEvent, case .throwAuthError = event.eventType else {
            return false
        }
        return true
    }

    /// A user pool that records each request's device key. With `refusingOnlyDeviceKeys`, it refuses only requests with
    /// a device key and signs the others in; otherwise it refuses every request.
    private static func userPool(_ requests: DeviceKeyRecorder, refusingOnlyDeviceKeys: Bool) -> MockIdentityProvider {
        let tokens = CognitoIdentityProviderClientTypes.AuthenticationResultType(
            accessToken: Defaults.validAccessToken,
            expiresIn: 3_600,
            idToken: "idToken",
            refreshToken: "refreshToken"
        )
        let answer: @Sendable (String?) throws -> Void = { deviceKey in
            requests.record(deviceKey)
            if deviceKey != nil || !refusingOnlyDeviceKeys {
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
            }
        }
        return MockIdentityProvider(
            mockInitiateAuthResponse: { input in
                try answer(input.authParameters?["DEVICE_KEY"])
                return InitiateAuthOutput(authenticationResult: tokens)
            },
            mockRespondToAuthChallengeResponse: { input in
                try answer(input.challengeResponses?["DEVICE_KEY"])
                return RespondToAuthChallengeOutput(authenticationResult: tokens)
            }
        )
    }
}

/// The device key of each request, in order.
private final class DeviceKeyRecorder: @unchecked Sendable {
    // `@unchecked Sendable`: `keys` is only touched while holding `lock`.
    private let lock = NSLock()
    private var keys: [String?] = []

    var deviceKeys: [String?] {
        lock.withLock { keys }
    }

    func record(_ key: String?) {
        lock.withLock { keys.append(key) }
    }
}

/// The events an action dispatched, in order.
private final class DispatchedEvents: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [StateMachineEvent] = []

    var events: [StateMachineEvent] {
        lock.withLock { recorded }
    }

    func record(_ event: StateMachineEvent) {
        lock.withLock { recorded.append(event) }
    }
}

/// The usernames whose device records were removed, in order.
private final class DeviceRecordRemovals: @unchecked Sendable {
    // `@unchecked Sendable`: `removed` is only touched while holding `lock`.
    private let lock = NSLock()
    private var removed: [String] = []

    var usernames: [String] {
        lock.withLock { removed }
    }

    func record(_ username: String) {
        lock.withLock { removed.append(username) }
    }
}

/// A credential store that forwards to `base` and records each device-record removal.
private struct RecordingCredentialStore: CredentialStoreStateBehavior {
    let base: CredentialStoreStateBehavior
    let removals: DeviceRecordRemovals

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        try await base.fetchData(type: type)
    }

    func storeData(data: CredentialStoreData) async throws {
        try await base.storeData(data: data)
    }

    func deleteData(type: CredentialStoreDataType) async throws {
        if case .deviceMetadata(let username) = type {
            removals.record(username)
        }
        try await base.deleteData(type: type)
    }
}
