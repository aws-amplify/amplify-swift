//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.AuthSignInStep` / `TOTPSetupDetails` and the engine's `EngineSignInStep` /
// `EngineTOTPSetupDetails`. Case to case, each payload through its own converter; `AdditionalInfo` passes
// through unchanged. Each switch has one arm per case, so they are exempt from the complexity rule.

// swiftlint:disable cyclomatic_complexity

extension AuthSignInStep {

    init(_ step: EngineSignInStep) {
        switch step {
        case .confirmSignInWithSMSMFACode(let details, let info):
            self = .confirmSignInWithSMSMFACode(AuthCodeDeliveryDetails(details), info)
        case .confirmSignInWithCustomChallenge(let info):
            self = .confirmSignInWithCustomChallenge(info)
        case .confirmSignInWithNewPassword(let info):
            self = .confirmSignInWithNewPassword(info)
        case .confirmSignInWithPassword:
            self = .confirmSignInWithPassword
        case .confirmSignInWithTOTPCode:
            self = .confirmSignInWithTOTPCode
        case .continueSignInWithTOTPSetup(let details):
            self = .continueSignInWithTOTPSetup(TOTPSetupDetails(details))
        case .continueSignInWithMFASelection(let types):
            self = .continueSignInWithMFASelection(Set(types.map { MFAType($0) }))
        case .continueSignInWithEmailMFASetup:
            self = .continueSignInWithEmailMFASetup
        case .continueSignInWithMFASetupSelection(let types):
            self = .continueSignInWithMFASetupSelection(Set(types.map { MFAType($0) }))
        case .confirmSignInWithOTP(let details):
            self = .confirmSignInWithOTP(AuthCodeDeliveryDetails(details))
        case .continueSignInWithFirstFactorSelection(let factors):
            self = .continueSignInWithFirstFactorSelection(Set(factors.map { AuthFactorType($0) }))
        case .resetPassword(let info):
            self = .resetPassword(info)
        case .confirmSignUp(let info):
            self = .confirmSignUp(info)
        case .done:
            self = .done
        }
    }
}

extension EngineSignInStep {

    init(_ step: AuthSignInStep) {
        switch step {
        case .confirmSignInWithSMSMFACode(let details, let info):
            self = .confirmSignInWithSMSMFACode(EngineCodeDeliveryDetails(details), info)
        case .confirmSignInWithCustomChallenge(let info):
            self = .confirmSignInWithCustomChallenge(info)
        case .confirmSignInWithNewPassword(let info):
            self = .confirmSignInWithNewPassword(info)
        case .confirmSignInWithPassword:
            self = .confirmSignInWithPassword
        case .confirmSignInWithTOTPCode:
            self = .confirmSignInWithTOTPCode
        case .continueSignInWithTOTPSetup(let details):
            self = .continueSignInWithTOTPSetup(EngineTOTPSetupDetails(details))
        case .continueSignInWithMFASelection(let types):
            self = .continueSignInWithMFASelection(Set(types.map { EngineMFAType($0) }))
        case .continueSignInWithEmailMFASetup:
            self = .continueSignInWithEmailMFASetup
        case .continueSignInWithMFASetupSelection(let types):
            self = .continueSignInWithMFASetupSelection(Set(types.map { EngineMFAType($0) }))
        case .confirmSignInWithOTP(let details):
            self = .confirmSignInWithOTP(EngineCodeDeliveryDetails(details))
        case .continueSignInWithFirstFactorSelection(let factors):
            self = .continueSignInWithFirstFactorSelection(Set(factors.map { EngineAuthFactorType($0) }))
        case .resetPassword(let info):
            self = .resetPassword(info)
        case .confirmSignUp(let info):
            self = .confirmSignUp(info)
        case .done:
            self = .done
        }
    }
}

// swiftlint:enable cyclomatic_complexity

extension TOTPSetupDetails {

    init(_ details: EngineTOTPSetupDetails) {
        self.init(sharedSecret: details.sharedSecret, username: details.username)
    }
}

extension EngineTOTPSetupDetails {

    init(_ details: TOTPSetupDetails) {
        self.init(sharedSecret: details.sharedSecret, username: details.username)
    }
}
