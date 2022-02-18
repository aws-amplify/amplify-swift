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
    let storedCredentials: CognitoCredentials?

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let authenticationEvent: AuthenticationEvent
        if let userPoolTokens = storedCredentials?.userPoolTokens {
            let signedInData = SignedInData(userId: "",
                                            userName: "",
                                            signedInDate: Date(),
                                            signInMethod: .srp,
                                            cognitoUserPoolTokens: userPoolTokens)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedIn(signedInData))
        } else {
            let signedOutData = SignedOutData(lastKnownUserName: nil)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))
        }
        logVerbose("\(#fileID) Sending event \(authenticationEvent.type)", environment: environment)
        dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration))
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
