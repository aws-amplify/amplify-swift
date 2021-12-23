//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct RefreshAWSCredentials: Command {

    public let identifier = "RefreshAWSCredentials"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: Implementation
        
        let fetchedTokenEvent = FetchAWSCredentialEvent(eventType: .fetched)
        timer.stop("### sending \(fetchedTokenEvent.type)")
        dispatcher.send(fetchedTokenEvent)
        
        let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession)
        timer.stop("### sending \(fetchIdentityEvent.type)")
        dispatcher.send(fetchIdentityEvent)
    }
}

extension RefreshAWSCredentials: DefaultLogger { }

extension RefreshAWSCredentials: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension RefreshAWSCredentials: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
