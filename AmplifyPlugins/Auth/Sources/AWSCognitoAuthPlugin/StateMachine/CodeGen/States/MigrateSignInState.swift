//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum MigrateSignInState: State {

    case notStarted
    case signingIn(SignInEventData)
    case signedIn(SignedInData)
    case error(SignInError)
}

extension MigrateSignInState {

    var type: String {
        switch self {
        case .notStarted: return "MigrateSignInState.notStarted"
        case .signingIn: return "MigrateSignInState.signingIn"
        case .signedIn: return "MigrateSignInState.signedIn"
        case .error: return "MigrateSignInState.error"
        }
    }

    static func == (lhs: MigrateSignInState, rhs: MigrateSignInState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.signingIn(let lhsData), .signingIn(let rhsData)):
            return lhsData == rhsData
        case (.signedIn(let lhsData), .signedIn(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsData), .error(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
