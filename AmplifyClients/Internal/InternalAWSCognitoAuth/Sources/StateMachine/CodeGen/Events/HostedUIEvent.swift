//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct HostedUIEvent: StateMachineEvent {
    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Sendable {

        case showHostedUI(HostedUISigningInState)

        case fetchToken(HostedUIResult)

        case throwError(SignInError)
    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .showHostedUI: return "HostedUIEvent.showHostedUI"
        case .fetchToken: return "HostedUIEvent.fetchToken"
        case .throwError: return "HostedUIEvent.throwError"
        }
    }

    package init(
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
    package static func == (lhs: HostedUIEvent.EventType, rhs: HostedUIEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.showHostedUI, .showHostedUI),
            (.fetchToken, .fetchToken):
            return true

        case (.throwError(let lhsError), .throwError(let rhsError)):
            return lhsError == rhsError

        default: return false
        }
    }
}
