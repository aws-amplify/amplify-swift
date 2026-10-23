//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

package struct WebAuthnEvent: StateMachineEvent {

    // `Sendable` because the enclosing event conforms to `StateMachineEvent`, which is `Sendable`.
    package enum EventType: Equatable, Sendable {
        case fetchCredentialOptions(Input)
        case assertCredentials(CredentialAssertionOptions, Input)
        case verifyCredentialsAndSignIn(String, Input)
        case signedIn(SignedInData)
        case error(WebAuthnError, RespondToAuthChallenge)
    }

    package let id: String
    package let eventType: EventType
    package let time: Date?

    package var type: String {
        switch eventType {
        case .fetchCredentialOptions: return "WebAuthnEvent.fetchCredentialOptions"
        case .assertCredentials: return "WebAuthnEvent.assertCredentials"
        case .verifyCredentialsAndSignIn: return "WebAuthnEvent.verifyCredentials"
        case .signedIn: return "WebAuthnEvent.signedIn"
        case .error: return "WebAuthnEvent.error"
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

    package struct Input: Equatable {
        package let username: String
        package let challenge: RespondToAuthChallenge
        package let presentationAnchor: EnginePresentationAnchor?

        package init(
            username: String,
            challenge: RespondToAuthChallenge,
            presentationAnchor: EnginePresentationAnchor?
        ) {
            self.username = username
            self.challenge = challenge
            self.presentationAnchor = presentationAnchor
        }
    }
}
#endif
