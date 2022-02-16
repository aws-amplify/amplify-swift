//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FetchAWSCredentialEvent: StateMachineEvent {
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
        case .fetch: return "FetchAWSCredentialEvent.fetch"
        case .fetched: return "FetchAWSCredentialEvent.fetched"
        case .throwError: return "FetchAWSCredentialEvent.throwError"
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
