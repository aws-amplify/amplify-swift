//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

enum DeleteUserState: State {

    /// Initial state for deleting the user
    case notStarted

    /// Delete user in progress
    case deletingUser

    /// Signing out the user after successfully deleting the user
    case signingOut(SignOutState)

    /// User successfully deleted
    case userDeleted(SignedOutData)

    /// Error occurred while deleting the user
    case error(AuthError)
}

extension DeleteUserState {

    var type: String {
        switch self {
        case .notStarted: return "DeleteUserState.notStarted"
        case .deletingUser: return "DeleteUserState.deletingUser"
        case .signingOut: return "DeleteUserState.signingOut"
        case .userDeleted: return "DeleteUserState.userDeleted"
        case .error: return "DeleteUserState.error"
        }
    }
}

extension DeleteUserState: Equatable {

    static func == (lhs: DeleteUserState, rhs: DeleteUserState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted), (.deletingUser, .deletingUser),
            (.userDeleted, .userDeleted), (.error, .error):
            return true
        case (.signingOut(let lhsData), .signingOut(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
