//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

typealias Username = String
typealias Password = String

struct SignInEvent: StateMachineEvent {

    var data: Any?

    enum EventType {

        case initiateSignInWithSRP(SignInEventData, DeviceMetadata)

        case initiateCustomSignIn(SignInEventData, DeviceMetadata)

        case initiateCustomSignInWithSRP(SignInEventData, DeviceMetadata)

        case initiateHostedUISignIn(HostedUIOptions)

        case initiateMigrateAuth(SignInEventData)

        case respondPasswordVerifier(SRPStateData, InitiateAuthOutputResponse)

        case throwPasswordVerifierError(SignInError)

        case finalizeSignIn(SignedInData)

        case cancelSRPSignIn(SignedInData)

        case throwAuthError(SignInError)

        case receivedChallenge(RespondToAuthChallenge)

        case verifySMSChallenge(String)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .initiateSignInWithSRP: return "SignInEvent.initiateSignInWithSRP"
        case .initiateCustomSignIn: return "SignInEvent.initiateCustomSignIn"
        case .initiateCustomSignInWithSRP: return "SignInEvent.initiateCustomSignInWithSRP"
        case .initiateHostedUISignIn: return "SignInEvent.initiateHostedUISignIn"
        case .initiateMigrateAuth: return "SignInEvent.initiateMigrateAuth"
        case .respondPasswordVerifier: return "SignInEvent.respondPasswordVerifier"
        case .throwPasswordVerifierError: return "SignInEvent.throwPasswordVerifierError"
        case .finalizeSignIn: return "SignInEvent.finalizeSignIn"
        case .cancelSRPSignIn: return "SignInEvent.cancelSRPSignIn"
        case .throwAuthError: return "SignInEvent.throwAuthError"
        case .receivedChallenge: return "SignInEvent.receivedChallenge"
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

        case (.initiateSignInWithSRP, .initiateSignInWithSRP),
            (.initiateHostedUISignIn, .initiateHostedUISignIn),
            (.initiateCustomSignIn, .initiateCustomSignIn),
            (.initiateCustomSignInWithSRP, .initiateCustomSignInWithSRP),
            (.initiateMigrateAuth, .initiateMigrateAuth),
            (.respondPasswordVerifier, .respondPasswordVerifier),
            (.throwPasswordVerifierError, .throwPasswordVerifierError),
            (.finalizeSignIn, .finalizeSignIn),
            (.cancelSRPSignIn, .cancelSRPSignIn),
            (.throwAuthError, .throwAuthError),
            (.receivedChallenge, .receivedChallenge),
            (.verifySMSChallenge, .verifySMSChallenge):
            return true
        default: return false
        }

    }
}
