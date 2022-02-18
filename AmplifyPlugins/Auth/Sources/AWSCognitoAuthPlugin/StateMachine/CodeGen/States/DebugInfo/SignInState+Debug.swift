//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {

        case .signingInWithSRP(let srpSignInState, let signInEventData):
            additionalMetadataDictionary = srpSignInState.debugDictionary.merging(
                signInEventData.debugDictionary, uniquingKeysWith: {$1}
            )
        default:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
