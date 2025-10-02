//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SRPSignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .initiatingSRPA(let signInEventData):
            signInEventData.debugDictionary
        case .cancelling:
            [:]
        case .respondingPasswordVerifier(let srpStateData):
            srpStateData.debugDictionary
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
