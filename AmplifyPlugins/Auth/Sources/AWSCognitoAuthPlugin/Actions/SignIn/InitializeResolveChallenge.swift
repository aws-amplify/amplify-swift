//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct InitializeResolveChallenge: Action {

    var identifier: String = "InitializeResolveChallenge"

    let challenge: RespondToAuthChallenge

    let signInMethod: SignInMethod

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let nextStep = try resolveNextSignInStep(for: challenge)
            let event = SignInChallengeEvent(eventType: .waitForAnswer(challenge, signInMethod, nextStep))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }

    private func resolveNextSignInStep(for challenge: RespondToAuthChallenge) throws -> AuthSignInStep {
        switch challenge.challenge.authChallengeType {
        case .smsMfa:
            let delivery = challenge.codeDeliveryDetails
            return .confirmSignInWithSMSMFACode(delivery, challenge.parameters)
        case .totpMFA:
            return .confirmSignInWithTOTPCode
        case .customChallenge:
            return .confirmSignInWithCustomChallenge(challenge.parameters)
        case .newPasswordRequired:
            return .confirmSignInWithNewPassword(challenge.parameters)
        case .passwordRequired:
            return .confirmSignInWithPassword
        case .selectMFAType:
            return .continueSignInWithMFASelection(challenge.getAllowedMFATypesForSelection)
        case .setUpMFA:
            var allowedMFATypesForSetup = challenge.getAllowedMFATypesForSetup
            // remove SMS, as it is not supported and should not be sent back to the customer, since it could be misleading
            allowedMFATypesForSetup.remove(.sms)
            if allowedMFATypesForSetup.count > 1 {
                return .continueSignInWithMFASetupSelection(allowedMFATypesForSetup)
            } else if let mfaType = allowedMFATypesForSetup.first,
                      mfaType == .email {
                return .continueSignInWithEmailMFASetup
            }
            throw SignInError.unknown(message: "Unable to determine next step from challenge:\n\(challenge)")
        case .unknown(let cognitoChallengeType):
            throw SignInError.unknown(message: "Challenge not supported\(cognitoChallengeType)")
        case .smsOTP, .emailOTP:
            let delivery = challenge.codeDeliveryDetails
            return .confirmSignInWithOTP(delivery)
        case .selectAuthFactor:
            return .continueSignInWithFirstFactorSelection(challenge.getAllowedAuthFactorsForSelection)
        }
    }

}

extension InitializeResolveChallenge: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "challenge": challenge.debugDictionary
        ]
    }
}

extension InitializeResolveChallenge: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
