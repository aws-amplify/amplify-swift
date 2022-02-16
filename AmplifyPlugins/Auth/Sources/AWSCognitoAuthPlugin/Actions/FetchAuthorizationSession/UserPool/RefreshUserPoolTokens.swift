//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider
import Foundation

struct RefreshUserPoolTokens: Action {

    let identifier = "RefreshUserPoolTokens"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment)
    {

        guard case let .success(cognitoUserPoolTokens) = cognitoSession.cognitoTokensResult else {
            let authZError = AuthorizationError.invalidState(
                message: "Refresh User Pool Tokens action will only be triggered in the success scenario")
            let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
            dispatcher.send(event)

            let updateCognitoSession = cognitoSession.copySessionByUpdating(
                cognitoTokensResult: .failure(authZError.authError))
            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
            dispatcher.send(fetchIdentityEvent)

            return
        }

        guard let environment = environment as? UserPoolEnvironment else {
            let authZError = AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError)
            let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
            dispatcher.send(event)

            let updateCognitoSession = cognitoSession.copySessionByUpdating(
                cognitoTokensResult: .failure(authZError.authError))
            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
            dispatcher.send(fetchIdentityEvent)

            return
        }

        let timer = LoggingTimer(identifier).start("### Starting execution")

        let userPoolClientId = environment.userPoolConfiguration.clientId
        let client = try? environment.cognitoUserPoolFactory()

        var authParameters: [String: String] = [
            "REFRESH_TOKEN": cognitoUserPoolTokens.refreshToken
        ]
        if let clientSecret = environment.userPoolConfiguration.clientSecret {
            authParameters["SECRET_HASH"] = clientSecret
        }

        let input = InitiateAuthInput(analyticsMetadata: nil,
                                      authFlow: .refreshTokenAuth,
                                      authParameters: authParameters,
                                      clientId: userPoolClientId,
                                      clientMetadata: nil,
                                      userContextData: nil)

        timer.note("### Starting initiateAuth refresh tokens")
        client?.initiateAuth(input: input,
                             completion: { result in
            timer.note("### initiateAuth refresh tokens response received")

            switch result {
            case .success(let response):
                guard let authenticationResult = response.authenticationResult,
                      let idToken = authenticationResult.idToken,
                      let accessToken = authenticationResult.accessToken
                else {

                          let authZError = AuthorizationError.invalidUserPoolTokens(
                            message: "UserPoolTokens are invalid.")
                          let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
                          dispatcher.send(event)

                          let updateCognitoSession = cognitoSession.copySessionByUpdating(
                            cognitoTokensResult: .failure(authZError.authError))
                          let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
                          dispatcher.send(fetchIdentityEvent)

                          timer.stop("### sending event \(fetchIdentityEvent.type)")
                          return
                      }

                let userPoolTokens = AWSCognitoUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: cognitoUserPoolTokens.refreshToken,
                    expiresIn: authenticationResult.expiresIn
                )

                let updateCognitoSession = cognitoSession.copySessionByUpdating(cognitoTokensResult: .success(userPoolTokens))

                let fetchedTokenEvent = FetchUserPoolTokensEvent(eventType: .fetched)
                timer.note("### sending event \(fetchedTokenEvent.type)")
                dispatcher.send(fetchedTokenEvent)

                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
                timer.stop("### sending event \(fetchIdentityEvent.type)")
                dispatcher.send(fetchIdentityEvent)
            case .failure(let error):
                let authError = AuthorizationError.service(error: error)
                let event = FetchUserPoolTokensEvent(eventType: .throwError(authError))
                dispatcher.send(event)

                // Update the cognito session with the relevant errors, so that subsequent states can act accordingly
                let updateCognitoSession: AWSAuthCognitoSession
                if case .notAuthorized = error.authError {
                    let result: Result<AuthCognitoTokens, AuthError>
                    result = .failure(
                        AuthError.sessionExpired(
                            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.errorDescription,
                            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.recoverySuggestion)
                    )
                    updateCognitoSession = cognitoSession.copySessionByUpdating(cognitoTokensResult: result)
                } else {
                    updateCognitoSession = cognitoSession.copySessionByUpdating(cognitoTokensResult: .failure(error.authError))
                }

                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
                timer.stop("### sending event \(fetchIdentityEvent.type)")
                dispatcher.send(fetchIdentityEvent)
            }
            timer.stop("### initiateAuth refresh tokens response complete")
        })

    }
}

extension RefreshUserPoolTokens: DefaultLogger { }

extension RefreshUserPoolTokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
