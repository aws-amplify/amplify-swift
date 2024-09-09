//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInTOTPSetupState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any] = switch self {
        case .waitingForAnswer(let signInTOTPSetupData):
            signInTOTPSetupData.debugDictionary
        case .verifying(let signInSetupData, let confirmSignInEventData):
            confirmSignInEventData.debugDictionary.merging(
                signInSetupData.debugDictionary,
                uniquingKeysWith: {$1}
            )
        case .error(let data, let error):
            [
                "totpSetupData": data ?? "Nil",
                "error": error
            ]
        default: [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
