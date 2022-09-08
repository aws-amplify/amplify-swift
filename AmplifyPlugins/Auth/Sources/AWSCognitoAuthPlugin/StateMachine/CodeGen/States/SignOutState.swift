//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider

enum SignOutState: State {
    case notStarted
    case signingOutGlobally
    case revokingToken
    case buildingRevokeTokenError
    case signingOutLocally(SignedInData?)
    case signingOutHostedUI(SignedInData)
    case signedOut(SignedOutData)
    case error(SignOutError)
}

extension SignOutState {
    var type: String {
        switch self {
        case .notStarted: return "SignOutState.notStarted"
        case .signingOutGlobally: return "SignOutState.signingOutGlobally"
        case .revokingToken: return "SignOutState.revokingToken"
        case .buildingRevokeTokenError: return "SignOutState.buildingRevokeTokenError"
        case .signingOutLocally: return "SignOutState.signingOutLocally"
        case .signingOutHostedUI: return "SignOutState.signingOutHostedUI"
        case .signedOut: return "SignOutState.signedOut"
        case .error: return "SignOutState.error"
        }
    }

    static func == (lhs: SignOutState, rhs: SignOutState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.signingOutGlobally, .signingOutGlobally):
            return true
        case (.revokingToken, .revokingToken):
            return true
        case (.buildingRevokeTokenError, .buildingRevokeTokenError):
            return true
        case (.signingOutLocally, .signingOutLocally):
            return true
        case (.signingOutHostedUI, .signingOutHostedUI):
            return true
        case (.signedOut(let lhsData), .signedOut(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsData), .error(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
