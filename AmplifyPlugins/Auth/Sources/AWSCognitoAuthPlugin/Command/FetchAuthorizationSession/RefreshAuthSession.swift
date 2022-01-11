//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct RefreshAuthSession: Command {

    public let identifier = "RefreshAuthSession"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO:


        // Refresh the session
        let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity)

        timer.stop("### sending FetchAuthSessionEvent.fetchIdentity")
        dispatcher.send(fetchIdentityEvent)
    }
}

extension RefreshAuthSession: DefaultLogger { }

extension RefreshAuthSession: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension RefreshAuthSession: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
