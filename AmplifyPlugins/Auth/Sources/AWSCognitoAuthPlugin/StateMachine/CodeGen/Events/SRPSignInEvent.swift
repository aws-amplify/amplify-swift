//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import hierarchical_state_machine_swift
import AWSCognitoIdentityProvider


public struct SRPSignInEvent: StateMachineEvent {
    public var data: Any?

    public enum EventType: Equatable {
        public static func == (lhs: SRPSignInEvent.EventType, rhs: SRPSignInEvent.EventType) -> Bool {
            return false
        }

        case initiateSRP(SignInEventData)
        case respondPasswordVerifier(SRPStateData, InitiateAuthOutputResponse)
        case throwPasswordVerifierError(AuthenticationError)
        case respondNextAuthChallenge(RespondToAuthChallengeOutputResponse)
        case finalizeSRPSignIn(SignedInData)
        case cancelSRPSignIn(SignedInData)
        case throwAuthError(AuthenticationError)
        case restoreToNotInitialized(SRPStateData)
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
        switch eventType {
        case .initiateSRP:
            return "initiateSRP"
        case .respondPasswordVerifier:
            return "respondPasswordVerifier"
        case .throwPasswordVerifierError:
            return "throwPasswordVerifierError"
        case .respondNextAuthChallenge:
            return "respondNextAuthChallenge"
        case .finalizeSRPSignIn:
            return "finalizeSRPSignIn"
        case .cancelSRPSignIn:
            return "cancelSRPSignIn"
        case .throwAuthError:
            return "throwAuthError"
        case .restoreToNotInitialized:
            return "restoreToNotInitialized"
        }
    }

    public init(
        id: String,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

