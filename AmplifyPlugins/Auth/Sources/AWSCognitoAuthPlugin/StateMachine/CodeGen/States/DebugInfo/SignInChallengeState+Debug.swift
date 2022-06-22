//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInChallengeState {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {

        case .waitingForAnswer(let respondAuthChallenge),
                .verifying(let respondAuthChallenge, _):
            additionalMetadataDictionary = respondAuthChallenge.debugDictionary
        case .error(let respondAuthChallenge, let error):
            additionalMetadataDictionary = respondAuthChallenge.debugDictionary
            additionalMetadataDictionary["error"] = error
        default: additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
