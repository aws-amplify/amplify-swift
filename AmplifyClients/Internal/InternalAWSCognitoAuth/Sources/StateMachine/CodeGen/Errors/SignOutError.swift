//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum SignOutError: Error {

    case hostedUI(HostedUIError)

    case localSignOut
}

extension SignOutError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .hostedUI(let error):
            return error.engineError
        case .localSignOut:
            return EngineAuthError.unknown("", nil)
        }
    }
}

extension SignOutError: Equatable {
    package static func == (lhs: SignOutError, rhs: SignOutError) -> Bool {
        switch (lhs, rhs) {
        case (.hostedUI, .hostedUI),
            (.localSignOut, .localSignOut):
            return true
        default:
            return false
        }
    }
}
