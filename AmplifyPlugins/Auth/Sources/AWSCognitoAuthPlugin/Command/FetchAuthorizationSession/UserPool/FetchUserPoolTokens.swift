//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct FetchUserPoolTokens: Command {

    public let identifier = "FetchUserPoolTokens"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")
        
        //TODO: Implemention
        
        let fetchedTokenEvent = FetchUserPoolTokensEvent(eventType: .fetched)
        timer.stop("### sending event \(fetchedTokenEvent.type)")
        dispatcher.send(fetchedTokenEvent)
        
        let fetchIdentityEvent = FetchAuthSessionEvent(eventType: .fetchIdentity)
        timer.stop("### sending event \(fetchIdentityEvent.type)")
        dispatcher.send(fetchIdentityEvent)
    }
}

extension FetchUserPoolTokens: DefaultLogger { }

extension FetchUserPoolTokens: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchUserPoolTokens: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
