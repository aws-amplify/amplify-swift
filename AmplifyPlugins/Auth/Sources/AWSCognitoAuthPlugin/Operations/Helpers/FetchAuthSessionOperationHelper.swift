//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Amplify
import AWSPluginsCore
import Foundation
import InternalAWSCognitoAuth

/// - Note: `final` and `@unchecked Sendable`: the helper is used from detached auth tasks and its
///   state is confined to a single fetch.
final class FetchAuthSessionOperationHelper: @unchecked Sendable {

    typealias FetchAuthSessionCompletion = (Result<AuthSession, AuthError>) -> Void
    var environment: Environment?

    func fetch(
        _ authStateMachine: AuthStateMachine,
        forceRefresh: Bool = false
    ) async throws -> AWSAuthCognitoSession {
        let state = await authStateMachine.currentState
        guard case .configured(_, let authorizationState, _) = state  else {
            let message = "Auth state machine not in configured state: \(state)"
            let error = AuthError.invalidState(message, "", nil)
            throw error
        }

        log.verbose("Fetching current state")
        switch authorizationState {
        case .configured:
            // If session has not been established, ask statemachine to invoke fetching
            // a fresh session.
            log.verbose("No session found, fetching unauth session")
            let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
            await authStateMachine.send(event)
            return try await listenForSession(authStateMachine: authStateMachine)

        case .sessionEstablished(let credentials):
            log.verbose("Session exists, checking validity")
            return try await refreshIfRequired(
                existingCredentials: credentials,
                authStateMachine: authStateMachine,
                forceRefresh: forceRefresh
            )

        case .error(let error):
            if case .sessionExpired(let error) = error {
                log.verbose("Session is expired")
                let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession(
                    underlyingError: error)
                return session
            } else if case .sessionError(_, let credentials) = error {
                // User-pool-only credentials with an identity pool configured mean the identity-pool step
                // failed. Their tokens can be valid (a refresh that failed at that step keeps its refreshed
                // tokens), so retry the refresh rather than returning a session without AWS credentials.
                if case .userPoolOnly = credentials,
                   (environment as? AuthEnvironment)?.identityPoolConfigData != nil {
                    log.verbose("Session has no identity pool credentials, refreshing")
                    let event = AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                    await authStateMachine.send(event)
                    return try await listenForSession(authStateMachine: authStateMachine)
                }
                return try await refreshIfRequired(
                    existingCredentials: credentials,
                    authStateMachine: authStateMachine,
                    forceRefresh: forceRefresh
                )
            } else {
                log.verbose("Session is in error state \(error)")
                let event = AuthorizationEvent(eventType: .fetchUnAuthSession)
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            }

        default:
            return try await listenForSession(authStateMachine: authStateMachine)
        }
    }

    func refreshIfRequired(
        existingCredentials credentials: AmplifyCredentials,
        authStateMachine: AuthStateMachine,
        forceRefresh: Bool
    ) async throws -> AWSAuthCognitoSession {

            if forceRefresh || !credentials.areValid() {
                let event = switch credentials {
                case .identityPoolWithFederation(let federatedToken, let identityId, _):
                    AuthorizationEvent(eventType: .startFederationToIdentityPool(federatedToken, identityId))
                case .noCredentials:
                    AuthorizationEvent(eventType: .fetchUnAuthSession)
                case .userPoolOnly, .identityPoolOnly, .userPoolAndIdentityPool:
                    AuthorizationEvent(eventType: .refreshSession(forceRefresh))
                }
                await authStateMachine.send(event)
                return try await listenForSession(authStateMachine: authStateMachine)
            } else {
                return credentials.cognitoSession
            }
        }

    func listenForSession(authStateMachine: AuthStateMachine) async throws -> AWSAuthCognitoSession {

        let stateSequences = await authStateMachine.listen()
        log.verbose("Waiting for session to establish")
        for await state in stateSequences {
            guard case .configured(let authenticationState, let authorizationState, _) = state  else {
                let message = "Auth state machine not in configured state: \(state)"
                let error = AuthError.invalidState(message, "", nil)
                throw error
            }

            switch authorizationState {
            case .sessionEstablished(let credentials):
                return credentials.cognitoSession
            case .error(let authorizationError):
                return try await sessionResultWithError(
                    authorizationError,
                    authenticationState: authenticationState
                )
            default: continue
            }
        }
        throw AuthError.invalidState(
            "Could not fetch session due to internal error",
            "Auth plugin is in an invalid state"
        )
    }

    func sessionResultWithError(
        _ error: AuthorizationError,
        authenticationState: AuthenticationState
    ) async throws -> AWSAuthCognitoSession {
        log.verbose("Received fetch auth session error - \(error)")

        var isSignedIn = false
        var authError: AuthError = error.authError

        if case .signedIn = authenticationState {
            isSignedIn = true
        }

        switch error {
        case .sessionError(let fetchError, let credentials):
            if (fetchError == .notAuthorized || fetchError == .noCredentialsToRefresh) && !isSignedIn {
                return AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess()
            } else if case .noIdentityPool = fetchError {
                // A missing identity pool must not fail the user-pool token result.
                return credentials.cognitoSession
            } else {
                authError = fetchError.authError
            }
        case .sessionExpired(let error):
            await setRefreshTokenExpiredInSignedInData()
            let session = AuthCognitoSignedInSessionHelper.makeExpiredSignedInSession(
                underlyingError: error)

            return session
        default:
            break
        }

        let session = AWSAuthCognitoSession(
            isSignedIn: isSignedIn,
            identityIdResult: .failure(authError),
            awsCredentialsResult: .failure(authError),
            cognitoTokensResult: .failure(authError)
        )
        return session
    }

    func setRefreshTokenExpiredInSignedInData() async {
        let credentialStoreClient = (environment as? AuthEnvironment)?.credentialsClient
        do {
            let data = try await credentialStoreClient?.fetchData(
                type: .amplifyCredentials
            )
            guard case .amplifyCredentials(var credentials) = data else {
                return
            }

            // Update SignedInData based on credential type
            switch credentials {
            case .userPoolOnly(var signedInData):
                signedInData.isRefreshTokenExpired = true
                credentials = .userPoolOnly(signedInData: signedInData)

            case .userPoolAndIdentityPool(var signedInData, let identityId, let awsCredentials):
                signedInData.isRefreshTokenExpired = true
                credentials = .userPoolAndIdentityPool(
                    signedInData: signedInData,
                    identityID: identityId,
                    credentials: awsCredentials
                )

            case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
                return
            }

            try await credentialStoreClient?.storeData(data: .amplifyCredentials(credentials))
        } catch EngineCredentialStoreError.itemNotFound {
            let logger = (environment as? LoggerProvider)?.logger
            logger?.info("No existing credentials found.")
        } catch {
            let logger = (environment as? LoggerProvider)?.logger
            logger?.error("Unable to update credentials with error: \(error)")
        }
    }
}

extension FetchAuthSessionOperationHelper {
    /// Routed through `environment` when it is set. `AWSAuthTaskHelper`'s helper has no environment,
    /// so its lines go through the global router.
    var log: EngineLogger {
        let scope = EngineLogScope.category("FetchAuthSessionOperationHelper")
        return (environment as? LoggerProvider)?.logger.scoped(scope) ?? EngineLog.logger(scope)
    }
}
