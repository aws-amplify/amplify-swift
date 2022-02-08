//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Docs: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html#API_SignUp_RequestParameters

struct SignUpPasswordValidator {
    static let maxPasswordLength = 256

    static func validate(password: String) -> SignUpError? {
        let error: SignUpError?

        if password.isEmpty {
            error = .invalidPassword(message: "password is empty")
        } else if password.count > maxPasswordLength {
            error = .invalidPassword(message: "password is over maximum length")
        } else if password.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            error = .invalidPassword(message: "password includes disallowed characters")
        } else {
            error = nil
        }

        return error
    }

}
