//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct RefreshAuthSession: Command {

    let identifier = "RefreshAuthSession"

    func execute(withDispatcher dispatcher: EventDispatcher,
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
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension RefreshAuthSession: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
