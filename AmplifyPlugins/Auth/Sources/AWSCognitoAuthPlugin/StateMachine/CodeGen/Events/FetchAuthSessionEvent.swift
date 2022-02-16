//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct FetchAuthSessionEvent: StateMachineEvent {
    enum EventType: Equatable {

        case fetchUserPoolTokens(AWSAuthCognitoSession)

        case fetchIdentity(AWSAuthCognitoSession)

        case fetchAWSCredentials(AWSAuthCognitoSession)

        case fetchedAuthSession(AWSAuthCognitoSession)

        case throwError(AuthorizationError)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .fetchUserPoolTokens: return "FetchAuthSessionEvent.fetchUserPoolTokens"
        case .fetchIdentity: return "FetchAuthSessionEvent.fetchIdentity"
        case .fetchAWSCredentials: return "FetchAuthSessionEvent.fetchAWSCredentials"
        case .fetchedAuthSession: return "FetchAuthSessionEvent.fetchedAuthSession"
        case .throwError: return "FetchAuthSessionEvent.throwError"
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
