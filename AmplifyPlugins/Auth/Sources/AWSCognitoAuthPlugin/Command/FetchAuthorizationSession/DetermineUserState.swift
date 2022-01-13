//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct DetermineUserState: Command {

    let identifier = "DetermineUserState"

    let authConfiguration: AuthConfiguration

    public func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) {

        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: complete the implementation
        let event = FetchAuthSessionEvent(eventType: .fetchUserPoolTokens)
        //OR
        //let event = FetchAuthSessionEvent(eventType: .fetchIdentity)

        timer.stop("### sending event \(event.type)")
        dispatcher.send(event)
    }
}

extension DetermineUserState: DefaultLogger { }

extension DetermineUserState: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "configuration": authConfiguration
        ]
    }
}

extension DetermineUserState: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
