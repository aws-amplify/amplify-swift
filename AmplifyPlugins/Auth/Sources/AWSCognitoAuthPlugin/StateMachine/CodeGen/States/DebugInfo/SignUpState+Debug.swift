//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignUpState {
    var debugDictionary: [String: Any] {
        switch self {
        case .notStarted:
            return ["SignUpState": "notStarted"]
        case .initiatingSigningUp:
            return ["SignUpState": "initiatingSigningUp"]
        case .signingUpInitiated:
            return ["SignUpState": "signingUpInitiated"]
        case .confirmingSignUp:
            return ["SignUpState": "confirmingSignUp"]
        case .signedUp:
            return ["SignUpState": "signedUp"]
        case .error:
            return ["SignUpState": "error"]
        }
    }
}
