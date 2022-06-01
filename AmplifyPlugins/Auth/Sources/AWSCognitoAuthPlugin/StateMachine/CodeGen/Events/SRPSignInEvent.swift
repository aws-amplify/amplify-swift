//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct SRPSignInEvent: StateMachineEvent {
    var data: Any?

    enum EventType: Equatable {
        static func == (lhs: SRPSignInEvent.EventType, rhs: SRPSignInEvent.EventType) -> Bool {
            return false
        }

        case initiateSRP(SignInEventData)
        case respondPasswordVerifier(SRPStateData, InitiateAuthOutputResponse)
        case throwPasswordVerifierError(SRPSignInError)
        case respondNextAuthChallenge(RespondToAuthChallengeOutputResponse)
        case finalizeSRPSignIn(SignedInData)
        case cancelSRPSignIn(SignedInData)
        case throwAuthError(SRPSignInError)
        case restoreToNotInitialized(SRPStateData)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .initiateSRP: return "SRPSignInEvent.initiateSRP"
        case .respondPasswordVerifier: return "SRPSignInEvent.respondPasswordVerifier"
        case .throwPasswordVerifierError: return "SRPSignInEvent.throwPasswordVerifierError"
        case .respondNextAuthChallenge: return "SRPSignInEvent.respondNextAuthChallenge"
        case .finalizeSRPSignIn: return "SRPSignInEvent.finalizeSRPSignIn"
        case .cancelSRPSignIn: return "SRPSignInEvent.cancelSRPSignIn"
        case .throwAuthError: return "SRPSignInEvent.throwAuthError"
        case .restoreToNotInitialized: return "SRPSignInEvent.restoreToNotInitialized"
        }
    }

    init(id: String = UUID().uuidString,
                eventType: EventType,
                time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
