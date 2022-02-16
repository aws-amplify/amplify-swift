//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FetchUserPoolTokensEvent: StateMachineEvent {
    enum EventType: Equatable {

        case refresh(AWSAuthCognitoSession)

        case fetched

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .refresh: return "FetchUserPoolTokensEvent.refresh"
        case .fetched: return "FetchUserPoolTokensEvent.fetched"
        case .throwError: return "FetchUserPoolTokensEvent.throwError"
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
