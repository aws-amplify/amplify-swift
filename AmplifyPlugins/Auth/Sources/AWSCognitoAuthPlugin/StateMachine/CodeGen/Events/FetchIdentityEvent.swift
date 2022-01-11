//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct FetchIdentityEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case fetch

        case fetched

    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .fetch: return "FetchIdentityEvent.fetch"
        case .fetched: return "FetchIdentityEvent.fetched"
        }
    }

    public init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

