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

    let existingCredentials: AWSCognitoUserPoolTokens

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        guard let environment = environment as? UserPoolEnvironment else {
            let event = RefreshSessionEvent.init(eventType: .throwError(.noUserPool))
            dispatcher.send(event)
            return
        }

        let config = environment.userPoolConfiguration
        let userPoolClientId = config.clientId
        let client = try? environment.cognitoUserPoolFactory()

        var authParameters: [String: String] = [
            "REFRESH_TOKEN": existingCredentials.refreshToken
        ]
        if let clientSecret = config.clientSecret {
            authParameters["SECRET_HASH"] = clientSecret
        }

        let input = InitiateAuthInput(analyticsMetadata: nil,
                                      authFlow: .refreshTokenAuth,
                                      authParameters: authParameters,
                                      clientId: userPoolClientId,
                                      clientMetadata: nil,
                                      userContextData: nil)

        logVerbose("\(#fileID) Starting initiate auth refresh token", environment: environment)

        Task {
            do {
                let response = try await client?.initiateAuth(input: input)

                logVerbose("\(#fileID) Initiate auth response received", environment: environment)

                guard let authenticationResult = response?.authenticationResult,
                      let idToken = authenticationResult.idToken,
                      let accessToken = authenticationResult.accessToken
                else {

                    let authZError = AuthorizationError.invalidUserPoolTokens(
                        message: "UserPoolTokens are invalid.")
                    let event = AuthorizationEvent(eventType: .throwError(authZError))
                    dispatcher.send(event)

                    logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                    return
                }

                let userPoolTokens = AWSCognitoUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: existingCredentials.refreshToken,
                    expiresIn: authenticationResult.expiresIn
                )
                let event: RefreshSessionEvent

                if ((environment as? AuthEnvironment)?.identityPoolConfigData) != nil {
                    let provider = CognitoUserPoolLoginsMap(idToken: idToken,
                                                            region: config.region,
                                                            poolId: config.poolId)
                    event = .init(eventType: .refreshIdentityInfo(userPoolTokens, provider))
                } else {
                    event = .init(eventType: .refreshedCognitoUserPool(userPoolTokens))
                }
                logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
                dispatcher.send(event)

            } catch {
                // TODO: To implement
                fatalError("")
            }

            logVerbose("\(#fileID) Initiate auth complete", environment: environment)
        }
    }
}

extension RefreshUserPoolTokens: DefaultLogger { }

extension RefreshUserPoolTokens: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "existingCredentials": existingCredentials
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
