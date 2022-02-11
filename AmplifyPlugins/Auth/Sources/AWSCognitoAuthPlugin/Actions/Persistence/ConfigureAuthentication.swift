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
        let timer = LoggingTimer(identifier).start("### Starting execution")
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
        timer.stop("### sending event \(authenticationEvent.type)")
        dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration))
        timer.stop("### sending event \(authStateEvent.type)")
        dispatcher.send(authStateEvent)
    }
}

extension ConfigureAuthentication: DefaultLogger { }

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
