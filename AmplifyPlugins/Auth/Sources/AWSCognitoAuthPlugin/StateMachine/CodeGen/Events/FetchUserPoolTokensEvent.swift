//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public struct FetchUserPoolTokensEvent: StateMachineEvent {
    public enum EventType: Equatable {

        case refresh(AWSAuthCognitoSession)
        
        case fetched
        
        case throwError(AuthorizationError)
        
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .refresh: return "FetchUserPoolTokensEvent.refresh"
        case .fetched: return "FetchUserPoolTokensEvent.fetched"
        case .throwError: return "FetchUserPoolTokensEvent.throwError"
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

