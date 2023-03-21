//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInSetupSoftwareTokenState: State {

    case notStarted

    case associateSoftwareToken

    case waitingForAnswer(AssociateSoftwareTokenData)

    case verifying(AssociateSoftwareTokenData, ConfirmSignInEventData)

    case respondingToAuthChallenge

    case success

    case error(SignInError)
}

extension SignInSetupSoftwareTokenState {

    var type: String {
        switch self {
        case .notStarted: return "SignInSetupSoftwareTokenState.notStarted"
        case .associateSoftwareToken: return "SignInSetupSoftwareTokenState.associateSoftwareToken"
        case .waitingForAnswer: return "SignInSetupSoftwareTokenState.waitingForAnswer"
        case .verifying: return "SignInSetupSoftwareTokenState.verifying"
        case .respondingToAuthChallenge: return "SignInSetupSoftwareTokenState.respondingToAuthChallenge"
        case .success: return "SignInSetupSoftwareTokenState.success"
        case .error: return "SignInSetupSoftwareTokenState.error"
        }
    }
}

extension SignInSetupSoftwareTokenState: Equatable {
    static func == (lhs: SignInSetupSoftwareTokenState, rhs: SignInSetupSoftwareTokenState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.associateSoftwareToken, .associateSoftwareToken),
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
