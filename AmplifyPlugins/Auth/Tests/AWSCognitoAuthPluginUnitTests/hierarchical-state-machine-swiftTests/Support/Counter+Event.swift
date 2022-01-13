//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension Counter {
    struct Event: StateMachineEvent {
        enum EventType {
            case increment
            case decrement
            case adjustBy(_ value: Int = 0)
            case set(Int)
            case incrementAndDoCommands([Command])
        }

        let id: String
        let eventType: EventType
        let source: String
        let time: Date?
        let data: Data?

        // Computed properties
        var type: String {
            switch eventType {
            case .adjustBy(let value):
                return "adjustBy.\(value)"
            case .increment:
                return "increment"
            case .decrement:
                return "decrement"
            case .set(let value):
                return "set.\(value)"
            case .incrementAndDoCommands:
                return "incrementAndDoCommands"
            }
        }

        init(
            id: String,
            eventType: EventType,
            source: String = "test",
            time: Date? = nil,
            data: Data? = nil
        ) {
            self.id = id
            self.eventType = eventType
            self.source = source
            self.time = time
            self.data = data
        }
    }
}
