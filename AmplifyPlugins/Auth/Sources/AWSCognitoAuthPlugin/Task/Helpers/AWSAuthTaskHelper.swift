//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

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
            guard case .configured(let authNState, _) = state else {
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
                        hostedUIError: data.hostedUIError)
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

        do {
            let tokens = try cognitoTokenProvider.getCognitoTokens().get()
            return tokens.accessToken
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown("Unable to fetch auth session", error)
        }
    }

}
