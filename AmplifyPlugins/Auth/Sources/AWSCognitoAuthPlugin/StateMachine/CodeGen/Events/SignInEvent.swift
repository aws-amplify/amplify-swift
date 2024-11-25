//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
#if os(iOS) || os(macOS) || os(visionOS)
import typealias Amplify.AuthUIPresentationAnchor
#endif

typealias Username = String
typealias Password = String
typealias ClientMetadata = [String: String]

struct SignInEvent: StateMachineEvent {

    var data: Any?

    enum EventType {

        case initiateSignInWithSRP(SignInEventData, DeviceMetadata, RespondToAuthChallenge?)

        case initiateCustomSignIn(SignInEventData, DeviceMetadata)

        case initiateCustomSignInWithSRP(SignInEventData, DeviceMetadata)

        case initiateHostedUISignIn(HostedUIOptions)

        case initiateMigrateAuth(SignInEventData, DeviceMetadata, RespondToAuthChallenge?)

        case initiateUserAuth(SignInEventData, DeviceMetadata)

        case initiateWebAuthnSignIn(WebAuthnSignInData, RespondToAuthChallenge)
        
        case initiateAutoSignIn(SignInEventData, DeviceMetadata)

        case respondPasswordVerifier(SRPStateData, SignInResponseBehavior, ClientMetadata)

        case retryRespondPasswordVerifier(SRPStateData, SignInResponseBehavior, ClientMetadata)

        case initiateDeviceSRP(Username, SignInResponseBehavior)

        case respondDeviceSRPChallenge(Username, SignInResponseBehavior)

        case respondDevicePasswordVerifier(SRPStateData, SignInResponseBehavior)

        case initiateTOTPSetup(Username, RespondToAuthChallenge)

        case throwPasswordVerifierError(SignInError)

        case finalizeSignIn(SignedInData)

        case confirmDevice(SignedInData)

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
        case .initiateUserAuth: return "SignInEvent.initiateUserAuth"
        case .initiateDeviceSRP: return "SignInEvent.initiateDeviceSRP"
        case .initiateAutoSignIn: return "SignInEvent.initiateAutoSignIn"
        case .respondDeviceSRPChallenge: return "SignInEvent.respondDeviceSRPChallenge"
        case .respondDevicePasswordVerifier: return "SignInEvent.respondDevicePasswordVerifier"
        case .respondPasswordVerifier: return "SignInEvent.respondPasswordVerifier"
        case .throwPasswordVerifierError: return "SignInEvent.throwPasswordVerifierError"
        case .confirmDevice: return "SignInEvent.confirmDevice"
        case .finalizeSignIn: return "SignInEvent.finalizeSignIn"
        case .cancelSRPSignIn: return "SignInEvent.cancelSRPSignIn"
        case .throwAuthError: return "SignInEvent.throwAuthError"
        case .receivedChallenge: return "SignInEvent.receivedChallenge"
        case .verifySMSChallenge: return "SignInEvent.verifySMSChallenge"
        case .retryRespondPasswordVerifier: return "SignInEvent.retryRespondPasswordVerifier"
        case .initiateTOTPSetup: return "SignInEvent.initiateTOTPSetup"
        case .initiateWebAuthnSignIn: return "SignInEvent.initiateWebAuthnSignIn"
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
            (.initiateDeviceSRP, .initiateDeviceSRP),
            (.respondDeviceSRPChallenge, .respondDeviceSRPChallenge),
            (.respondDevicePasswordVerifier, .respondDevicePasswordVerifier),
            (.respondPasswordVerifier, .respondPasswordVerifier),
            (.throwPasswordVerifierError, .throwPasswordVerifierError),
            (.finalizeSignIn, .finalizeSignIn),
            (.confirmDevice, .confirmDevice),
            (.cancelSRPSignIn, .cancelSRPSignIn),
            (.throwAuthError, .throwAuthError),
            (.receivedChallenge, .receivedChallenge),
            (.verifySMSChallenge, .verifySMSChallenge),
            (.retryRespondPasswordVerifier, .retryRespondPasswordVerifier),
            (.initiateTOTPSetup, .initiateTOTPSetup):
            return true
        default: return false
        }

    }
}
