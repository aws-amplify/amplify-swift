//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInTOTPSetupState {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .waitingForAnswer(let signInTOTPSetupData):
            additionalMetadataDictionary = signInTOTPSetupData.debugDictionary
        case .verifying(let signInSetupData, let confirmSignInEventData):
            additionalMetadataDictionary = confirmSignInEventData.debugDictionary
            additionalMetadataDictionary = additionalMetadataDictionary.merging(
                signInSetupData.debugDictionary,
                uniquingKeysWith: {$1})
        case .error(let error):
            additionalMetadataDictionary["error"] = error
        default: additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
