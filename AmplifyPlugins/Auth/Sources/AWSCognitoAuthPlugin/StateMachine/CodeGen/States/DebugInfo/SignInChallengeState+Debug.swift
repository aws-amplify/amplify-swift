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
                .verifying(let respondAuthChallenge, _),
                .error(let respondAuthChallenge):
            additionalMetadataDictionary = respondAuthChallenge.debugDictionary
        default: additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
