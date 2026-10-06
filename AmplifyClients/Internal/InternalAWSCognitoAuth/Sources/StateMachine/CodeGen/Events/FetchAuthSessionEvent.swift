//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package typealias IdentityID = String
package typealias ForceRefresh = Bool

package struct FetchAuthSessionEvent: StateMachineEvent {
    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Sendable {

        case fetchUnAuthIdentityID

        case fetchAuthenticatedIdentityID(LoginsMapProvider)

        case fetchedIdentityID(IdentityID)

        case fetchAWSCredentials(IdentityID, LoginsMapProvider)

        case fetchedAWSCredentials(IdentityID, EngineAWSCredentials)

        case fetched(IdentityID, EngineAWSCredentials)

        case throwError(FetchSessionError)

    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .fetchUnAuthIdentityID:
            return "FetchAuthSessionEvent.fetchUnAuthIdentityID"
        case .fetchAuthenticatedIdentityID:
            return "FetchAuthSessionEvent.fetchAuthenticatedIdentityID"
        case .fetchedIdentityID:
            return "FetchAuthSessionEvent.fetchedIdentityID"
        case .fetchAWSCredentials:
            return "FetchAuthSessionEvent.fetchAWSCredentials"
        case .fetchedAWSCredentials:
            return "FetchAuthSessionEvent.fetchedAWSCredentials"
        case .throwError:
            return "FetchAuthSessionEvent.throwError"
        case .fetched:
            return "FetchAuthSessionEvent.fetched"
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
