//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AuthenticationState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        switch self {
        case .notConfigured:
            return ["AuthenticationState": "notConfigured"]

        case .configured:
            return ["AuthenticationState": "configured"]

        case .signingOut(let authenticationConfiguration, let signOutState):
            return [
                "AuthenticationState":  "signingOut",
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
                "- SignOutState": signOutState.debugDictionary
            ]

        case .signedOut(let authenticationConfiguration, let signedOutData):
            return [
                "AuthenticationState": "signedOut",
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
                "- SignedOutData": signedOutData.debugDictionary
            ]

        case .signingUp(let authenticationConfiguration, let signUpState):
            return [
                "AuthenticationState": "signingUp",
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
                "- SignUpState": signUpState.debugDictionary
            ]

        case .signingIn(let authenticationConfiguration, let signInState):
            return [
                "AuthenticationState": "signingIn",
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
