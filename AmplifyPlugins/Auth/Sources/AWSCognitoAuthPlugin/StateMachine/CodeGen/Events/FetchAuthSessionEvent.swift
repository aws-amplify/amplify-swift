//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct FetchAuthSessionEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case fetchUserPoolTokens(AWSAuthCognitoSession)

        case fetchIdentity(AWSAuthCognitoSession)

        case fetchAWSCredentials(AWSAuthCognitoSession)

        case fetchedAuthSession(AWSAuthCognitoSession)

        case throwError(AuthorizationError)

    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .fetchUserPoolTokens: return "FetchAuthSessionEvent.fetchUserPoolTokens"
        case .fetchIdentity: return "FetchAuthSessionEvent.fetchIdentity"
        case .fetchAWSCredentials: return "FetchAuthSessionEvent.fetchAWSCredentials"
        case .fetchedAuthSession: return "FetchAuthSessionEvent.fetchedAuthSession"
        case .throwError: return "FetchAuthSessionEvent.throwError"
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
