//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

enum SignOutError: Error {

    case hostedUI(HostedUIError)

    case localSignOut
}

extension SignOutError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .hostedUI(let error):
            return error.authError
        case .localSignOut:
            return AuthError.unknown("", nil)
        }
    }
}

extension SignOutError: Equatable {
    static func == (lhs: SignOutError, rhs: SignOutError) -> Bool {
        switch (lhs, rhs) {
        case (.hostedUI, .hostedUI),
            (.localSignOut, .localSignOut):
            return true
        default:
            return false
        }
    }
}
