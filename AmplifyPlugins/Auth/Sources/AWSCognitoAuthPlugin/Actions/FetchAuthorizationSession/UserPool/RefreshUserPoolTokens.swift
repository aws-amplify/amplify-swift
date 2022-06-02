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
import ClientRuntime

struct RefreshUserPoolTokens: Action {

    let identifier = "RefreshUserPoolTokens"

    let cognitoSession: AWSAuthCognitoSession

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {
//        guard case let .success(cognitoUserPoolTokens) = cognitoSession.cognitoTokensResult else {
//            let authZError = AuthorizationError.invalidState(
//                message: "Refresh User Pool Tokens action will only be triggered in the success scenario")
//            let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
//            dispatcher.send(event)
//
//            let updateCognitoSession = cognitoSession.copySessionByUpdating(
//                cognitoTokensResult: .failure(authZError.authError))
//            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
//            dispatcher.send(fetchIdentityEvent)
//
//            return
//        }
//
//        guard let environment = environment as? UserPoolEnvironment else {
//            let authZError = AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError)
//            let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
//            dispatcher.send(event)
//
//            let updateCognitoSession = cognitoSession.copySessionByUpdating(
//                cognitoTokensResult: .failure(authZError.authError))
//            let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
//            dispatcher.send(fetchIdentityEvent)
//
//            return
//        }
//
//        logVerbose("\(#fileID) Starting execution", environment: environment)
//
//        let userPoolClientId = environment.userPoolConfiguration.clientId
//        let client = try? environment.cognitoUserPoolFactory()
//
//        var authParameters: [String: String] = [
//            "REFRESH_TOKEN": cognitoUserPoolTokens.refreshToken
//        ]
//        if let clientSecret = environment.userPoolConfiguration.clientSecret {
//            authParameters["SECRET_HASH"] = clientSecret
//        }
//
//        let input = InitiateAuthInput(analyticsMetadata: nil,
//                                      authFlow: .refreshTokenAuth,
//                                      authParameters: authParameters,
//                                      clientId: userPoolClientId,
//                                      clientMetadata: nil,
//                                      userContextData: nil)
//
//        logVerbose("\(#fileID) Starting initiate auth refresh token", environment: environment)
//
//        Task {
//            do {
//                let response = try await client?.initiateAuth(input: input)
//
//                logVerbose("\(#fileID) Initiate auth response received", environment: environment)
//
//                guard let authenticationResult = response?.authenticationResult,
//                      let idToken = authenticationResult.idToken,
//                      let accessToken = authenticationResult.accessToken
//                else {
//
//                    let authZError = AuthorizationError.invalidUserPoolTokens(
//                        message: "UserPoolTokens are invalid.")
//                    let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
//                    dispatcher.send(event)
//
//                    let updateCognitoSession = cognitoSession.copySessionByUpdating(
//                        cognitoTokensResult: .failure(authZError.authError))
//                    let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
//                    dispatcher.send(fetchIdentityEvent)
//
//                    logVerbose("\(#fileID) Sending event \(fetchIdentityEvent.type)",
//                               environment: environment)
//                    return
//                }
//
//                let userPoolTokens = AWSCognitoUserPoolTokens(
//                    idToken: idToken,
//                    accessToken: accessToken,
//                    refreshToken: cognitoUserPoolTokens.refreshToken,
//                    expiresIn: authenticationResult.expiresIn
//                )
//
//                let updateCognitoSession = cognitoSession.copySessionByUpdating(cognitoTokensResult: .success(userPoolTokens))
//
//                let fetchedTokenEvent = FetchUserPoolTokensEvent(eventType: .fetched)
//                logVerbose("\(#fileID) Sending event \(fetchedTokenEvent.type)",
//                           environment: environment)
//                dispatcher.send(fetchedTokenEvent)
//
//                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
//                logVerbose("\(#fileID) Sending event \(fetchIdentityEvent.type)",
//                           environment: environment)
//                dispatcher.send(fetchIdentityEvent)
//
//            } catch {
//                let sdkError = error as? SdkError<InitiateAuthOutputError> ?? SdkError.unknown(error)
//                let authZError = AuthorizationError.service(error: error)
//                let event = FetchUserPoolTokensEvent(eventType: .throwError(authZError))
//                dispatcher.send(event)
//
//                // Update the cognito session with the relevant errors, so that subsequent states can act accordingly
//                let updateCognitoSession: AWSAuthCognitoSession
//                if case .notAuthorized = sdkError.authError {
//                    let result: Result<AuthCognitoTokens, AuthError>
//                    result = .failure(
//                        AuthError.sessionExpired(
//                            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.errorDescription,
//                            AuthPluginErrorConstants.cognitoTokensSessionExpiredError.recoverySuggestion)
//                    )
//                    updateCognitoSession = cognitoSession.copySessionByUpdating(cognitoTokensResult: result)
//                } else {
//                    updateCognitoSession = cognitoSession.copySessionByUpdating(
//                        cognitoTokensResult: .failure(sdkError.authError)
//                    )
//                }
//
//                let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity(updateCognitoSession))
//                logVerbose("\(#fileID) Sending event \(fetchIdentityEvent.type)",
//                           environment: environment)
//                dispatcher.send(fetchIdentityEvent)
//            }
//
//            logVerbose("\(#fileID) Initiate auth complete", environment: environment)
//        }
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
