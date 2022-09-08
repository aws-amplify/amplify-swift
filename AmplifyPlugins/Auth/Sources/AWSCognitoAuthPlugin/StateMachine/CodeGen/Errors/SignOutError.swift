//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum SignOutError: Error {

    case userCancelled

    case localSignOut
}

extension SignOutError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .userCancelled:
            return AuthError.service("", "", AWSCognitoAuthError.userCancelled)
        case .localSignOut:
            return AuthError.unknown("", nil)
        }
    }
}
