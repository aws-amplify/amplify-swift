//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FetchIdentityEvent: StateMachineEvent {
    enum EventType: Equatable {

        case fetch(AWSAuthCognitoSession)

        case fetched

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .fetch: return "FetchIdentityEvent.fetch"
        case .fetched: return "FetchIdentityEvent.fetched"
        case .throwError: return "FetchIdentityEvent.throwError"
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
