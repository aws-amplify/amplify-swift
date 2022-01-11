//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct AuthorizationSessionEstablished: Command {

    public let identifier = "AuthorizationSessionEstablished"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation


        let authorizationSessionEvent = AuthorizationEvent(eventType: .fetchedAuthSession(AuthorizationSessionData()))
        timer.stop("### sending \(authorizationSessionEvent.type)")
        dispatcher.send(authorizationSessionEvent)

        let event = AuthEvent(eventType: .authorizationConfigured)
        timer.stop("### sending \(event.type)")
        dispatcher.send(event)
    }
}

extension AuthorizationSessionEstablished: DefaultLogger { }

extension AuthorizationSessionEstablished: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension AuthorizationSessionEstablished: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
