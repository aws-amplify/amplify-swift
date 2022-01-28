//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public struct AuthorizationEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case configure(AuthConfiguration)

        case fetchAuthSession

        case fetchedAuthSession(AWSAuthCognitoSession)
        
        case throwError(AuthorizationError)
        
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .configure: return "AuthorizationEvent.configure"
        case .fetchAuthSession: return "AuthorizationEvent.fetchAuthSession"
        case .fetchedAuthSession: return "AuthorizationEvent.fetchedAuthSession"
        case .throwError: return "AuthorizationEvent.throwError"
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

