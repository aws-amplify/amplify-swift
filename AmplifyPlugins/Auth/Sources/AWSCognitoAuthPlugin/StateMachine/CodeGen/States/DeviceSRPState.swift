//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider

enum DeviceSRPState: State {

    case notStarted
    case initiatingDeviceSRP(SRPStateData)
    case respondingDevicePasswordVerifier(SRPStateData)
    case signedIn(SignedInData)
    case error(SignInError)
    case cancelling
}

extension DeviceSRPState {

    var type: String {
        switch self {
        case .notStarted: return "SRPSignInState.notStarted"
        case .initiatingDeviceSRP: return "SRPSignInState.initiatingDeviceSRPA"
        case .cancelling: return "SRPSignInState.cancelling"
        case .respondingDevicePasswordVerifier: return "SRPSignInState.respondingDevicePasswordVerifier"
        case .signedIn: return "SRPSignInState.signedIn"
        case .error: return "SRPSignInState.error"
        }
    }

    static func == (lhs: DeviceSRPState, rhs: DeviceSRPState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted):
            return true
        case (.initiatingDeviceSRP(let lhsData), .initiatingDeviceSRP(let rhsData)):
            return lhsData == rhsData
        case (.cancelling, .cancelling):
            return true
        case (.respondingDevicePasswordVerifier(let lhsData), .respondingDevicePasswordVerifier(let rhsData)):
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
