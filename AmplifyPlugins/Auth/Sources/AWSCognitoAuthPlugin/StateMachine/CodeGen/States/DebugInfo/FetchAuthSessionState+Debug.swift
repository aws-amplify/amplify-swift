//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState {

    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["FetchAuthSessionState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .initializingFetchAuthSession:
            additionalMetadataDictionary = [:]
        case .fetchingUserPoolTokens:
            additionalMetadataDictionary = [:]
        case .fetchingIdentity:
            additionalMetadataDictionary = [:]
        case .fetchingAWSCredentials:
            additionalMetadataDictionary = [:]
        case .sessionEstablished:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }

}
