//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .fetchingIdentityID:
            additionalMetadataDictionary = [:]
        case .fetchingAWSCredentials:
            additionalMetadataDictionary = [:]
        case .fetched:
            additionalMetadataDictionary = [:]
        case .error(let error):
            additionalMetadataDictionary = ["error": error]
        }
        return [type: additionalMetadataDictionary]
    }

}
