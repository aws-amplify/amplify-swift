//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInTOTPSetupState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any]
        switch self {
        case .waitingForAnswer(let signInTOTPSetupData):
            additionalMetadataDictionary = signInTOTPSetupData.debugDictionary
        case .verifying(let signInSetupData, let confirmSignInEventData):
            additionalMetadataDictionary = confirmSignInEventData.debugDictionary.merging(
                signInSetupData.debugDictionary,
                uniquingKeysWith: {$1})
        case .error(let data, let error):
            additionalMetadataDictionary = [
                "totpSetupData": data ?? "Nil",
                "error": error
            ]
        default: additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
