//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift
import Foundation

public struct LoadPersistedAuthentication: Command {
    public let identifier = "LoadPersistedAuthentication"
    public let configuration: AuthConfiguration

    public enum PersistedAuthenticationState {
        case signedIn(SignedInData)
        case signedOut(SignedOutData)
    }

    public struct Environment: hierarchical_state_machine_swift.Environment {
        /// Eventually this will probably need to get the Auth configuration so it knows
        /// what to check
        let loader: () -> PersistedAuthenticationState
    }

    public func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: hierarchical_state_machine_swift.Environment
    ) {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        let signedOutData = SignedOutData(authenticationConfiguration: configuration, lastKnownUserName: nil)
        let authenticationEvent = AuthenticationEvent(eventType: .initializedSignedOut(signedOutData))

        timer.stop("### Sending AuthenticationEvent.initializedSignedOut")
        dispatcher.send(authenticationEvent)
        
        let authStateEvent = AuthEvent(eventType: .authenticationConfigured(configuration))
        dispatcher.send(authStateEvent)
    }
}

extension LoadPersistedAuthentication: DefaultLogger { }

extension LoadPersistedAuthentication: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": configuration.debugDictionary
        ]
    }
}

extension LoadPersistedAuthentication: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
