//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation

class AWSAuthTaskHelper: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper

    init(authStateMachine: AuthStateMachine) {
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func didStateMachineConfigured() async {
        log.verbose("Check if authstate configured")
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            if case .configured = state {
                log.verbose("Auth state configured")
                return
            }
        }
    }

    func didSignOut() async -> AuthSignOutResult {
        let stateSequences = await authStateMachine.listen()
        log.verbose("Waiting for signOut completion")
        for await state in stateSequences {
            guard case .configured(let authNState, _, _) = state else {
                let error = AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError, nil)
                return AWSCognitoSignOutResult.failed(error)
            }

            switch authNState {
            case .signedOut(let data):
                if data.revokeTokenError != nil ||
                    data.globalSignOutError != nil ||
                    data.hostedUIError != nil {
                    return AWSCognitoSignOutResult.partial(
                        revokeTokenError: data.revokeTokenError,
                        globalSignOutError: data.globalSignOutError,
                        hostedUIError: data.hostedUIError
                    )
                }
                return AWSCognitoSignOutResult.complete
            case .signingIn:
                log.verbose("Cancel if a signIn is in progress")
                await authStateMachine.send(AuthenticationEvent.init(eventType: .cancelSignIn))
            case .signingOut(let state):
                if case .error(let error) = state {
                    return AWSCognitoSignOutResult.failed(error.authError)
                }
            default:
                continue
            }
        }
        fatalError()
    }

    func getAccessToken() async throws -> String {

        let session = try await fetchAuthSessionHelper.fetch(authStateMachine)
        guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider else {
            throw AuthError.unknown("Unable to fetch auth session", nil)
        }

        let tokens = try cognitoTokenProvider.getCognitoTokens().get()
        return tokens.accessToken
    }

    func getCurrentUser() async throws -> any AuthUser {
        await didStateMachineConfigured()
        let authState = await authStateMachine.currentState

        guard case .configured(let authenticationState, _, _) = authState else {
            throw AuthError.configuration(
                "Plugin not configured",
                AuthPluginErrorConstants.configurationError
            )
        }

        switch authenticationState {
        case .notConfigured:
            throw AuthError.configuration("UserPool configuration is missing", AuthPluginErrorConstants.configurationError)
        case .signedIn(let signInData):
            let authUser = AWSAuthUser(username: signInData.username, userId: signInData.userId)
            return authUser
        case .signedOut, .configured:
            throw AuthError.signedOut(
                "There is no user signed in to retrieve current user",
                "Call Auth.signIn to sign in a user and then call Auth.getCurrentUser", nil
            )
        case .error(let authNError):
            throw authNError.authError
        default:
            throw AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError, nil)
        }
    }

    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }

    var log: Logger {
        Self.log
    }

}
