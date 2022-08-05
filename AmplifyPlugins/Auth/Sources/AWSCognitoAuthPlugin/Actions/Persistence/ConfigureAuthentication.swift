//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ConfigureAuthentication: Action {

    let identifier = "ConfigureAuthentication"
    let configuration: AuthConfiguration
    let storedCredentials: AmplifyCredentials

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let authenticationEvent: AuthenticationEvent
        switch storedCredentials {
        case .userPoolOnly(let tokens), .userPoolAndIdentityPool(let tokens, _, _):
            do {
                let authUser = try TokenParserHelper.getAuthUser(accessToken: tokens.accessToken)
                let signedInData = SignedInData(
                    userId: authUser.userId,
                    userName: authUser.username,
                    signedInDate: Date(),
                    signInMethod: .apiBased(.userSRP),
                    cognitoUserPoolTokens: tokens)
                authenticationEvent = AuthenticationEvent(eventType: .initializedSignedIn(signedInData))
            } catch {
                authenticationEvent = AuthenticationEvent(
                    eventType: .error(AuthenticationError.service(
                        message: "Token parsing error: \(error)")))
            }
        default:
            let signedOutData = SignedOutData(lastKnownUserName: nil)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))
        }

        logVerbose("\(#fileID) Sending event \(authenticationEvent.type)", environment: environment)
        dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration,
                                                                            storedCredentials))
        logVerbose("\(#fileID) Sending event \(authStateEvent.type)", environment: environment)
        dispatcher.send(authStateEvent)
    }
}

extension ConfigureAuthentication: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration.debugDictionary
        ]
    }
}

extension ConfigureAuthentication: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
