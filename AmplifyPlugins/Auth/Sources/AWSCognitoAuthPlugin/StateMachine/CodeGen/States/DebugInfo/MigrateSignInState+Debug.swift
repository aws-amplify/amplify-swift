//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension MigrateSignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any] = switch self {

        case .notStarted:
            [:]
        case .signingIn:
            [:]
        case .signedIn(let signedInData):
            ["SignedInData": signedInData.debugDictionary]
        case .error:
            [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
