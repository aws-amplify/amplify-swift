//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct FetchAuthIdentityId: Command {

    public let identifier = "FetchAuthIdentityId"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implement Fetch Identity

        let fetchIdentityEvent = FetchIdentityEvent(eventType: .fetched)
        timer.stop("### sending event \(fetchIdentityEvent.type)")
        dispatcher.send(fetchIdentityEvent)

        let fetchAwsCredentialsEvent = FetchAuthSessionEvent(
            eventType: .fetchAWSCredentials)
        timer.stop("### sending event \(fetchAwsCredentialsEvent.type)")
        dispatcher.send(fetchAwsCredentialsEvent)

    }
}

extension FetchAuthIdentityId: DefaultLogger { }

extension FetchAuthIdentityId: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthIdentityId: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
