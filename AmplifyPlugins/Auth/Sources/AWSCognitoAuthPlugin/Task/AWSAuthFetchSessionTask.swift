//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(KeychainStore) import AWSPluginsCore

class AWSAuthFetchSessionTask: AuthFetchSessionTask, DefaultLogger {
    private let request: AuthFetchSessionRequest
    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private let taskHelper: AWSAuthTaskHelper
    private let configuration: AuthConfiguration
    private let credentialsClient: CredentialStoreStateBehavior?
    private let isKeychainSharingEnabled: Bool

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchSessionAPI
    }

    init(
        _ request: AuthFetchSessionRequest,
        authStateMachine: AuthStateMachine,
        configuration: AuthConfiguration,
        environment: Environment,
        isKeychainSharingEnabled: Bool = false
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        fetchAuthSessionHelper.environment = environment
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.configuration = configuration
        self.credentialsClient = (environment as? AuthEnvironment)?.credentialsClient
        self.isKeychainSharingEnabled = isKeychainSharingEnabled
    }

    func execute() async throws -> AuthSession {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()
        if isKeychainSharingEnabled {
            await reconcileWithSharedKeychainIfNeeded()
        }
        let doesNeedForceRefresh = request.options.forceRefresh
        return try await fetchAuthSessionHelper.fetch(
            authStateMachine,
            forceRefresh: doesNeedForceRefresh
        )
    }

    /// When the plugin is configured with a shared keychain access group, the
    /// keychain is the source of truth across processes. Reconcile the local
    /// state machine with whatever is currently in the keychain — but only
    /// when doing so won't destroy locally-originated in-flight work.
    ///
    /// Decision matrix (auth state vs. remote-vs-local credentials):
    /// - quiescent (.signedIn / .signedOut / .error / .configured / .notConfigured)
    ///     - differ: reconfigure (sibling wrote — pick it up)
    ///     - match: no-op
    /// - .signingIn
    ///     - remote has user-pool tokens: reconfigure (adopt sibling's sign-in;
    ///       confirmSignIn will resolve to .done)
    ///     - remote has no user-pool tokens: defer (sign-in flow finishes;
    ///       last-writer-wins on the keychain)
    /// - .signingOut / .deletingUser / .federatingToIdentityPool /
    ///   .clearingFederation: defer (in-flight side effects must run; same end
    ///   state is reached by the local flow)
    func reconcileWithSharedKeychainIfNeeded() async {
        guard let keychainCredentials = await fetchCredentialsFromKeychain() else {
            return
        }
        guard case .configured(let authNState, let authZState, _) = await authStateMachine.currentState else {
            return
        }
        let stateMachineCredentials = fetchCredentialsFromStateMachine(authZState)
        if let stateMachineCredentials, stateMachineCredentials == keychainCredentials {
            return
        }

        if shouldDeferReconcile(authNState: authNState, remote: keychainCredentials) {
            log.verbose("Deferring keychain reconcile while auth flow is in progress")
            return
        }

        log.verbose("Reconfiguring auth state machine for keychain sharing")
        let event = AuthEvent(eventType: .reconfigure(configuration))
        await authStateMachine.send(event)
        await taskHelper.didStateMachineConfigured()
    }

    private func fetchCredentialsFromKeychain() async -> AmplifyCredentials? {
        do {
            let data = try await credentialsClient?.fetchData(type: .amplifyCredentials)
            if case .amplifyCredentials(let credentials) = data {
                return credentials
            }
            return nil
        } catch KeychainStoreError.itemNotFound {
            return .noCredentials
        } catch {
            log.verbose("Could not read shared keychain credentials: \(error)")
            return nil
        }
    }

    /// Best-effort snapshot of the credentials the local state machine last
    /// observed. Returns nil for transient authZ states where we can't make a
    /// reliable comparison; in those cases callers fall back to deferring (the
    /// transient state will resolve shortly and a later fetch will reconcile).
    private func fetchCredentialsFromStateMachine(_ authZState: AuthorizationState) -> AmplifyCredentials? {
        switch authZState {
        case .sessionEstablished(let credentials),
             .storingCredentials(let credentials):
            return credentials
        case .refreshingSession(existingCredentials: let credentials, _):
            return credentials
        case .federatingToIdentityPool(_, _, existingCredentials: let credentials):
            return credentials
        case .signingOut(let credentials):
            return credentials ?? .noCredentials
        case .configured:
            return .noCredentials
        case .notConfigured,
             .clearingFederation,
             .fetchingUnAuthSession,
             .fetchingAuthSessionWithUserPool,
             .deletingUser,
             .error:
            return nil
        }
    }

    private func shouldDeferReconcile(
        authNState: AuthenticationState,
        remote: AmplifyCredentials
    ) -> Bool {
        switch authNState {
        case .signingIn:
            // Adopt sibling sign-in; otherwise defer until local flow completes
            return !remote.hasUserPoolTokens
        case .signingOut,
             .deletingUser,
             .federatingToIdentityPool,
             .clearingFederation:
            return true
        case .notConfigured,
             .configured,
             .signedIn,
             .signedOut,
             .federatedToIdentityPool,
             .error:
            return false
        }
    }

}
