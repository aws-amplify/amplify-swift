//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

struct SignInEvent: StateMachineEvent {
    var data: Any?

    enum EventType {
        case initiateSRP(SignInEventData)
        case respondPasswordVerifier(SRPStateData, InitiateAuthOutputResponse)
        case throwPasswordVerifierError(SignInError)
        case respondNextAuthChallenge(RespondToAuthChallengeOutputResponse)
        case finalizeSRPSignIn(SignedInData)
        case cancelSRPSignIn(SignedInData)
        case throwAuthError(SignInError)
        case restoreToNotInitialized(SRPStateData)
        case receivedSMSChallenge(RespondToAuthChallenge)
        case verifySMSChallenge(String)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .initiateSRP: return "SignInEvent.initiateSRP"
        case .respondPasswordVerifier: return "SignInEvent.respondPasswordVerifier"
        case .throwPasswordVerifierError: return "SignInEvent.throwPasswordVerifierError"
        case .respondNextAuthChallenge: return "SignInEvent.respondNextAuthChallenge"
        case .finalizeSRPSignIn: return "SignInEvent.finalizeSRPSignIn"
        case .cancelSRPSignIn: return "SignInEvent.cancelSRPSignIn"
        case .throwAuthError: return "SignInEvent.throwAuthError"
        case .restoreToNotInitialized: return "SignInEvent.restoreToNotInitialized"
        case .receivedSMSChallenge: return "SignInEvent.respondWithSMSChallenge"
        case .verifySMSChallenge: return "SignInEvent.verifySMSChallenge"
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

extension SignInEvent.EventType: Equatable {

    static func == (lhs: SignInEvent.EventType, rhs: SignInEvent.EventType) -> Bool {
        switch (lhs, rhs) {

        case (.initiateSRP, .initiateSRP),
            (.respondPasswordVerifier, .respondPasswordVerifier),
            (.throwPasswordVerifierError, .throwPasswordVerifierError),
            (.respondNextAuthChallenge, .respondNextAuthChallenge),
            (.finalizeSRPSignIn, .finalizeSRPSignIn),
            (.cancelSRPSignIn, .cancelSRPSignIn),
            (.throwAuthError, .throwAuthError),
            (.restoreToNotInitialized, .restoreToNotInitialized),
            (.receivedSMSChallenge, .receivedSMSChallenge),
            (.verifySMSChallenge, .verifySMSChallenge):
            return true
        default: return false
        }
        
    }
}
