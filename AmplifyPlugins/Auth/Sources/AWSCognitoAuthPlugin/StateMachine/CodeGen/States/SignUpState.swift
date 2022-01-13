//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

public enum SignUpState: State {
    case notStarted
    case initiatingSigningUp
    case signingUpInitiated
    case confirmingSignUp
    case signedUp
    case error
}

public extension SignUpState {
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
}
