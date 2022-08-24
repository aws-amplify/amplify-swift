//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias IdentityID = String
typealias ForceRefresh = Bool

struct FetchAuthSessionEvent: StateMachineEvent {
    enum EventType {

        case fetchUnAuthIdentityID

        case fetchAuthenticatedIdentityID(LoginsMapProvider)

        case fetchedIdentityID(IdentityID)

        case fetchAWSCredentials(IdentityID, LoginsMapProvider)

        case fetchedAWSCredentials(IdentityID, AuthAWSCognitoCredentials)

        case fetched(IdentityID, AuthAWSCognitoCredentials)

        case throwError(FetchSessionError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
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
