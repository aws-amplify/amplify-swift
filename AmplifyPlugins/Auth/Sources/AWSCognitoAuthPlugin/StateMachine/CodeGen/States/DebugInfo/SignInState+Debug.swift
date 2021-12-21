//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension SignInState {

    var debugDictionary: [String: Any] {

        switch self {

        case .signingInWithSRP(let srpSignInState, let signInEventData):
            return [
                "SignInState": "signingInWithSRP",
                "- SRPSignInState": srpSignInState.debugDictionary,
                "- SignInEventData": signInEventData.debugDictionary
            ]
        case .signingInWithSocial:
            return [
                "SignInState": "signingInWithSocial"
            ]
        case .signingInWithCustom:
            return [
                "SignInState": "signingInWithCustom"
            ]
        case .resolvingMFAChallenge:
            return [
                "SignInState": "resolvingMFAChallenge"
            ]
        }
    }
}
