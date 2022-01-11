//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct AuthorizationEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case configure(AuthConfiguration)

        case fetchAuthSession(AuthConfiguration)

        case fetchedAuthSession(AuthorizationSessionData)

        case validateSession(AuthConfiguration)

        case sessionIsValid

        case error
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .configure: return "AuthorizationEvent.configure"
        case .fetchAuthSession: return "AuthorizationEvent.fetchAuthSession"
        case .fetchedAuthSession: return "AuthorizationEvent.fetchedAuthSession"
        case .validateSession: return "AuthorizationEvent.validateSession"
        case .sessionIsValid: return "AuthorizationEvent.sessionIsValid"
        case .error: return ""
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
