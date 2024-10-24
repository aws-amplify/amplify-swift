//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct WebAuthnEvent: StateMachineEvent {

    enum EventType: Equatable {
        case fetchCredentialOptions(Input)
        case assertCredentials(CredentialAssertionOptions, Input)
        case verifyCredentialsAndSignIn(String, Input)
        case signedIn(SignedInData)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .fetchCredentialOptions: return "WebAuthnEvent.fetchCredentialOptions"
        case .assertCredentials: return "WebAuthnEvent.assertCredentials"
        case .verifyCredentialsAndSignIn: return "WebAuthnEvent.verifyCredentials"
        case .signedIn: return "WebAuthnEvent.signedIn"
        }
    }

    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }

    struct Input: Equatable {
        let username: String
        let challenge: RespondToAuthChallenge
        let presentationAnchor: AuthUIPresentationAnchor?
    }
}
