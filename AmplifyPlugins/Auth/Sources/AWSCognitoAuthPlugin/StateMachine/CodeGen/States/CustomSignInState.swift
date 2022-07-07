//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider

enum CustomSignInState: State {

    case notStarted
    case initiating(SignInEventData)
    case signedIn(SignedInData)
    case error(SignInError)
}

extension CustomSignInState {

    var type: String {
        switch self {
        case .notStarted: return "CustomSignInState.notStarted"
        case .initiating: return "CustomSignInState.initiating"
        case .signedIn: return "CustomSignInState.signedIn"
        case .error: return "CustomSignInState.error"
        }
    }

    static func == (lhs: CustomSignInState, rhs: CustomSignInState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.initiating(let lhsData), .initiating(let rhsData)):
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
