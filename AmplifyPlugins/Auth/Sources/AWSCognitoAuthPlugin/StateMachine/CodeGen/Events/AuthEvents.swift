//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public struct AuthEvent: StateMachineEvent {

    public enum EventType: Equatable {

        case configureAuth(AuthConfiguration)
        
        case configureCredentialStore(AuthConfiguration)

        case configureAuthentication(AuthConfiguration)

        case configureAuthorization(AuthConfiguration)

        case authenticationConfigured(AuthConfiguration)

        case authorizationConfigured
    }

    public var id: String

    public let eventType: EventType

    public var time: Date?

    public var type: String {
        switch eventType {
        case .configureAuth: return "AuthEvent.configureAuth"
        case .configureCredentialStore: return "AuthEvent.configureCredentialStore"
        case .configureAuthentication: return "AuthEvent.configureAuthentication"
        case .configureAuthorization: return "AuthEvent.configureAuthorization"
        case .authenticationConfigured: return "AuthEvent.authenticationConfigured"
        case .authorizationConfigured: return "AuthEvent.authorizationConfigured"
        }
    }

    public init(id: String = UUID().uuidString,
                eventType: EventType,
                time: Date? = Date())
    {
        self.id = id
        self.eventType = eventType
        self.time = time
    }

}
