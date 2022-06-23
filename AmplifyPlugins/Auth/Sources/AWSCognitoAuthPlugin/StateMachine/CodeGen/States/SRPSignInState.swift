//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider

enum SRPSignInState: State {

    case notStarted
    case initiatingSRPA(SignInEventData)
    case respondingPasswordVerifier(SRPStateData)
    case signedIn(SignedInData)
    case error(SignInError)
    case cancelling
}

extension SRPSignInState {

    var type: String {
        switch self {
        case .notStarted: return "SRPSignInState.notStarted"
        case .initiatingSRPA: return "SRPSignInState.initiatingSRPA"
        case .cancelling: return "SRPSignInState.cancelling"
        case .respondingPasswordVerifier: return "SRPSignInState.respondingPasswordVerifier"
        case .signedIn: return "SRPSignInState.signedIn"
        case .error: return "SRPSignInState.error"
        }
    }

    static func == (lhs: SRPSignInState, rhs: SRPSignInState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.initiatingSRPA(let lhsData), .initiatingSRPA(let rhsData)):
            return lhsData == rhsData
        case (.cancelling, .cancelling):
            return true
        case (.respondingPasswordVerifier(let lhsData), .respondingPasswordVerifier(let rhsData)):
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
