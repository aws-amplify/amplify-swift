//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension SignOutState {

    var debugDictionary: [String: Any] {

        switch self {
        case .notStarted:
            return [
                "SignOutState": "notStarted"
            ]
        case .signingOutGlobally:
            return [
                "SignOutState": "signingOutGlobally"
            ]
        case .revokingToken:
            return [
                "SignOutState": "revokingToken"
            ]
        case .signingOutLocally:
            return [
                "SignOutState": "signingOutLocally"
            ]
        case .signedOut:
            return [
                "SignOutState": "signedOut",
            ]
        case .error(let error):
            return [
                "SignOutState": "error",
                "- AuthenticationError": error
            ]
        }
    }
}

