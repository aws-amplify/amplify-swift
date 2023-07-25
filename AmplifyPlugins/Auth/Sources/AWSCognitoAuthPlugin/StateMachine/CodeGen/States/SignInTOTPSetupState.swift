//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInTOTPSetupState: State {

    case notStarted

    case setUpTOTP

    case waitingForAnswer(SignInTOTPSetupData)

    case verifying(SignInTOTPSetupData, ConfirmSignInEventData)

    case respondingToAuthChallenge

    case success

    case error(SignInTOTPSetupData?, SignInError)
}

extension SignInTOTPSetupState {

    var type: String {
        switch self {
        case .notStarted: return "SignInTOTPSetupState.notStarted"
        case .setUpTOTP: return "SignInTOTPSetupState.setUpTOTP"
        case .waitingForAnswer: return "SignInTOTPSetupState.waitingForAnswer"
        case .verifying: return "SignInTOTPSetupState.verifying"
        case .respondingToAuthChallenge: return "SignInTOTPSetupState.respondingToAuthChallenge"
        case .success: return "SignInTOTPSetupState.success"
        case .error: return "SignInTOTPSetupState.error"
        }
    }
}

extension SignInTOTPSetupState: Equatable {
    static func == (lhs: SignInTOTPSetupState, rhs: SignInTOTPSetupState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.setUpTOTP, .setUpTOTP),
            (.waitingForAnswer, .waitingForAnswer),
            (.verifying, .verifying),
            (.respondingToAuthChallenge, .respondingToAuthChallenge),
            (.success, .success),
            (.error, .error):
            return true
        default: return false
        }
    }

}
