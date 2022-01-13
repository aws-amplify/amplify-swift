//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct ConfigureFetchIdentity: Command {

    let identifier = "ConfigureFetchIdentity"

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation


        let fetchIdentity = FetchIdentityEvent(eventType: .fetch)
        timer.stop("### sending event \(fetchIdentity.type)")
        dispatcher.send(fetchIdentity)
    }
}

extension ConfigureFetchIdentity: DefaultLogger { }

extension ConfigureFetchIdentity: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureFetchIdentity: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
