//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

enum SignUpState: State {
    case notStarted
    case initiatingSigningUp(SignUpEventData)
    case signingUpInitiated(username: String, response: SignUpOutputResponse)
    case confirmingSignUp(ConfirmSignUpEventData)
    case signedUp
    case error(SignUpError)
}

extension SignUpState {
    var type: String {
        switch self {
        case .notStarted:
            return "SignUpState.notStarted"
        case .initiatingSigningUp:
            return "SignUpState.initiatingSigningUp"
        case .signingUpInitiated:
            return "SignUpState.signingUpInitiated"
        case .confirmingSignUp:
            return "SignUpState.confirmingSignUp"
        case .signedUp:
            return "SignUpState.signedUp"
        case .error:
            return "SignUpState.error"
        }
    }

    static func == (lhs: SignUpState, rhs: SignUpState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.initiatingSigningUp(let lhsData), .initiatingSigningUp(let rhsData)):
            return lhsData == rhsData
        case (.signingUpInitiated, .signingUpInitiated):
            return true
        case (.confirmingSignUp(let lhsData), .confirmingSignUp(let rhsData)):
            return lhsData == rhsData
        case (.signedUp, .signedUp):
            return true
        case (.error(let lhsData), .error(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
