//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState: CustomDebugDictionaryConvertible {

    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any] = switch self {
        case .notStarted:
            [:]
        case .fetchingIdentityID:
            [:]
        case .fetchingAWSCredentials:
            [:]
        case .fetched:
            [:]
        case .error(let error):
            ["error": error]
        }
        return [type: additionalMetadataDictionary]
    }

}
