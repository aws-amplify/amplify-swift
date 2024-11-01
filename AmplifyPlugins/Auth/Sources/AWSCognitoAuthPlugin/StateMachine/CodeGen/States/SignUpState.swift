//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum SignUpState: State {
    case notStarted
    case initiatingSignUp(SignUpEventData)
    case awaitingUserConfirmation(SignUpEventData, AuthSignUpResult)
    case confirmingSignUp(SignUpEventData)
    case signedUp(SignUpEventData, AuthSignUpResult)
    case error(SignUpError)
}

extension SignUpState {
    
    var type: String {
        switch self {
        case .notStarted: return "SignUpState.notStarted"
        case .initiatingSignUp: return "SignUpState.initiatingSignUp"
        case .awaitingUserConfirmation: return "SignUpState.awaitingUserConfirmation"
        case .confirmingSignUp: return "SignUpState.confirmingSignUp"
        case .signedUp: return "SignUpState.signedUp"
        case .error: return "SignUpState.error"
        }
    }
}

extension SignUpState {
    static func == (lhs: SignUpState, rhs: SignUpState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.initiatingSignUp, .initiatingSignUp),
            (.awaitingUserConfirmation, .awaitingUserConfirmation),
            (.confirmingSignUp, .confirmingSignUp),
            (.signedUp, .signedUp),
            (.error, .error):
            return true
        default: return false
        }
    }
    
}
