//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

extension AuthenticationState: CustomDebugDictionaryConvertible {

    public var debugDictionary: [String: Any] {
        switch self {
        case .notConfigured:
            return ["AuthenticationState": "notConfigured"]

        case .configured:
            return ["AuthenticationState": "configured"]

        case .signedOut(let signedOutData):
            return [
                "AuthenticationState": "signedOut",
                "- SignedOutData": signedOutData.debugDictionary
            ]

        case .signingIn(let authenticationConfiguration, let signInState):
            return [
                "AuthenticationState":  "signingIn",
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
                "- SignInState": signInState.debugDictionary
            ]

        case .signedIn(let authenticationConfiguration, let signedInData):
            return [
                "AuthenticationState": "signedIn",
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
                "- SignInState": signedInData.debugDictionary
            ]

        case .error(_, let error):
            return [
                "AuthenticationState": "error",
                "- AuthenticationError": error
            ]
        }
    }

}

extension AuthenticationState: CustomDebugStringConvertible { }
