//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

struct LoadPersistedAuthentication: Command {
    let identifier = "LoadPersistedAuthentication"
    let configuration: AuthConfiguration

    enum PersistedAuthenticationState {
        case signedIn(SignedInData)
        case signedOut(SignedOutData)
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation

        let signedOutData = SignedOutData(authenticationConfiguration: configuration, lastKnownUserName: nil)
        let authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))
        timer.stop("### sending event \(authenticationEvent.type)")
        dispatcher.send(authenticationEvent)

        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration))
        timer.stop("### sending event \(authStateEvent.type)")
        dispatcher.send(authStateEvent)
    }
}

extension LoadPersistedAuthentication: DefaultLogger { }

extension LoadPersistedAuthentication: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration.debugDictionary
        ]
    }
}

extension LoadPersistedAuthentication: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
