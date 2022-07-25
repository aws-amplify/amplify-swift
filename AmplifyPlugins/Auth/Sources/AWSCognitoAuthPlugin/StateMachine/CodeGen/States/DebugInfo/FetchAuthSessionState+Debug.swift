//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .fetchingIdentityID:
            additionalMetadataDictionary = [:]
        case .fetchingAWSCredentials:
            additionalMetadataDictionary = [:]
        case .fetched:
            additionalMetadataDictionary = [:]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }

}
