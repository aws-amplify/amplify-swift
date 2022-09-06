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
    ) async {
        logVerbose("\(#fileID) Start execution", environment: environment)
        let authenticationEvent: AuthenticationEvent
        switch storedCredentials {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedIn(signedInData))
        case .identityPoolWithFederation:
            authenticationEvent = AuthenticationEvent(eventType: .initializedFederated)
        default:
            let signedOutData = SignedOutData(lastKnownUserName: nil)
            authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))
        }

        logVerbose("\(#fileID) Sending event \(authenticationEvent.type)", environment: environment)
        await dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration,
                                                                            storedCredentials))
        logVerbose("\(#fileID) Sending event \(authStateEvent.type)", environment: environment)
        await dispatcher.send(authStateEvent)
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
