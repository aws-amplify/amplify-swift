//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct HostedUIEvent: StateMachineEvent {
    enum EventType {

        case showHostedUI(HostedUISigningInState)

        case fetchToken(HostedUIResult)

        case throwError(SignInError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .showHostedUI: return "HostedUIEvent.showHostedUI"
        case .fetchToken: return "HostedUIEvent.fetchToken"
        case .throwError: return "HostedUIEvent.throwError"
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
        case (.showHostedUI, .showHostedUI),
            (.fetchToken, .fetchToken):
            return true
        case (.throwError(let lhsError), .throwError(let rhsError)):
            return lhsError == rhsError

        default: return false
        }
    }
}
