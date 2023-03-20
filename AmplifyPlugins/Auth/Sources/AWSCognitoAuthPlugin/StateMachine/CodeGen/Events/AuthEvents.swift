//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AuthEvent: StateMachineEvent {

    enum EventType: Equatable {

        case configureAuth(AuthConfiguration)

        case validateCredentialAndConfiguration(AuthConfiguration, AmplifyCredentials)

        case configureAuthentication(AuthConfiguration, AmplifyCredentials)

        case configureAuthorization(AuthConfiguration, AmplifyCredentials)

        case authenticationConfigured(AuthConfiguration, AmplifyCredentials)

        case authorizationConfigured

        case reconfigure(AuthConfiguration)
    }

    var id: String

    let eventType: EventType

    var time: Date?

    var type: String {
        switch eventType {
        case .configureAuth: return "AuthEvent.configureAuth"
        case .configureAuthentication: return "AuthEvent.configureAuthentication"
        case .configureAuthorization: return "AuthEvent.configureAuthorization"
        case .authenticationConfigured: return "AuthEvent.authenticationConfigured"
        case .authorizationConfigured: return "AuthEvent.authorizationConfigured"
        case .validateCredentialAndConfiguration: return "AuthEvent.validateCredentialAndConfiguration"
        case .reconfigure: return "AuthEvent.reconfigure"
        }
    }

    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = Date()) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }

}
