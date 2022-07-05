//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct HostedUIEvent: StateMachineEvent {
    enum EventType {

        case showHostedUI(HostedUISignInData)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {

        case .showHostedUI:
            return "HostedUIEvent.showHostedUI"
        }
    }

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

extension HostedUIEvent.EventType: Equatable {
    static func == (lhs: HostedUIEvent.EventType, rhs: HostedUIEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.showHostedUI, .showHostedUI):
            return true
//        default: return false
        }
    }
}
