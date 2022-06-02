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

    let exitingTokens: AWSCognitoUserPoolTokens

    let identityID: IdentityID?

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
            "REFRESH_TOKEN": exitingTokens.refreshToken
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
                    refreshToken: exitingTokens.refreshToken,
                    expiresIn: authenticationResult.expiresIn
                )
                let event: RefreshSessionEvent
                if let identityID = identityID {
                    let provider = CognitoUserPoolLoginsMap(idToken: idToken,
                                                            region: config.region,
                                                            poolId: config.poolId)
                    event = .init(eventType: .refreshAWSCredentialsWithUserPool(identityID, userPoolTokens, provider))
                } else if ((environment as? AuthEnvironment)?.identityPoolConfigData) != nil {
                    event = .init(eventType: .fetchIdentityInfo(userPoolTokens))
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
            "identifier": identifier
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
