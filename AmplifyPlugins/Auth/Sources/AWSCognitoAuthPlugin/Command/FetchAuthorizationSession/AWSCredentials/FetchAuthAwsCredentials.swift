//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct FetchAuthAWSCredentials: Command {

    public let identifier = "FetchAuthAwsCredentials"

    public func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation


        let fetchedAWSCredentialEvent = FetchAWSCredentialEvent(eventType: .fetched)
        timer.stop("### sending \(fetchedAWSCredentialEvent.type)")
        dispatcher.send(fetchedAWSCredentialEvent)

        let fetchedAuthSessionEvent = FetchAuthSessionEvent(eventType: .fetchedAuthSession)
        timer.stop("### sending \(fetchedAuthSessionEvent.type)")
        dispatcher.send(fetchedAuthSessionEvent)

    }
}

extension FetchAuthAWSCredentials: DefaultLogger { }

extension FetchAuthAWSCredentials: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension FetchAuthAWSCredentials: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
