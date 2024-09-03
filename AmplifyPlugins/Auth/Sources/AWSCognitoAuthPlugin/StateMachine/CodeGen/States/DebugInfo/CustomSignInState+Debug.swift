//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CustomSignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .initiating(let signInEventData):
            signInEventData.debugDictionary
        case .signedIn(let signedInData):
            signedInData.debugDictionary
        case .error(let error):
            [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }
}
