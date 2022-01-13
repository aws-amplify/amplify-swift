//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct AuthorizationSessionEstablished: Command {

    let identifier = "AuthorizationSessionEstablished"

    func execute(withDispatcher dispatcher: EventDispatcher,
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
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension AuthorizationSessionEstablished: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
