//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct ConfigureFetchIdentity: Command {
    
    public let identifier = "ConfigureFetchIdentity"
    
    public func execute(withDispatcher dispatcher: EventDispatcher,
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
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureFetchIdentity: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
