//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct ConfigureFetchAWSCredentials: Command {
    
    public let identifier = "ConfigureFetchAWSCredentials"
    
    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: Implementation
        
        
        // Refresh the session
        let fetchIdentity = FetchAWSCredentialEvent(eventType: .fetch)
        timer.stop("### sending \(fetchIdentity.type)")
        dispatcher.send(fetchIdentity)
    }
}

extension ConfigureFetchAWSCredentials: DefaultLogger { }

extension ConfigureFetchAWSCredentials: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureFetchAWSCredentials: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
