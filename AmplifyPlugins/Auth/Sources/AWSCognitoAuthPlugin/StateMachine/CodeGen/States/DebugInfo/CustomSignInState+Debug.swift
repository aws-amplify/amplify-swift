//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CustomSignInState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .initiating(let signInEventData):
            additionalMetadataDictionary = signInEventData.debugDictionary
        case .signedIn(let signedInData):
            additionalMetadataDictionary = signedInData.debugDictionary
        case .error(let error):
            additionalMetadataDictionary = [
                "Error": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }
}
