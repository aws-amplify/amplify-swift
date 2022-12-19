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

        case .waitingForAnswer(let respondAuthChallenge, _),
                .verifying(let respondAuthChallenge, _, _):
            additionalMetadataDictionary = respondAuthChallenge.debugDictionary
        case .error(let respondAuthChallenge, _, let error):
            additionalMetadataDictionary = respondAuthChallenge.debugDictionary
            additionalMetadataDictionary["error"] = error
        default: additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
