//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignUpState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any]

        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .initiatingSignUp(let data):
            additionalMetadataDictionary = data.debugDictionary
        case .awaitingUserConfirmation:
            additionalMetadataDictionary = [:]
        case .confirmingSignUp(let data):
            additionalMetadataDictionary = data.debugDictionary
        case .signedUp(let data, _):
            additionalMetadataDictionary = data.debugDictionary
        case .error(let signUpError):
            additionalMetadataDictionary = ["Error": signUpError]
        }
        return [type: additionalMetadataDictionary]
    }
}
