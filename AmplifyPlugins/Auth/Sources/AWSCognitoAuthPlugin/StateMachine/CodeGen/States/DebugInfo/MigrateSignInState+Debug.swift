//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension MigrateSignInState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {

        let additionalMetadataDictionary: [String: Any]

        switch self {

        case .notStarted:
            additionalMetadataDictionary = [:]
        case .signingIn:
            additionalMetadataDictionary = [:]
        case .signedIn(let signedInData):
            additionalMetadataDictionary = ["SignedInData": signedInData.debugDictionary]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
