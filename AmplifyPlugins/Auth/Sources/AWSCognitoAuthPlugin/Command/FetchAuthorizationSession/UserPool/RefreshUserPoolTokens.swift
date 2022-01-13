//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct RefreshUserPoolTokens: Command {

    public let identifier = "RefreshUserPoolTokens"

    func execute(withDispatcher dispatcher: EventDispatcher,
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

extension RefreshUserPoolTokens: DefaultLogger { }

extension RefreshUserPoolTokens: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension RefreshUserPoolTokens: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
