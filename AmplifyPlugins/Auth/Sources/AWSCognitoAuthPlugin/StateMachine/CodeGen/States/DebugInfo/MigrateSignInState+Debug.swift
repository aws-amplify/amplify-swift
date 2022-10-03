//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension MigrateSignInState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {

        case .notStarted:
            additionalMetadataDictionary = [:]
        case .signingIn(_):
            additionalMetadataDictionary = [:]
        case .signedIn(let signedInData):
            additionalMetadataDictionary = ["SignedInData": signedInData.debugDictionary]
        case .error(_):
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
