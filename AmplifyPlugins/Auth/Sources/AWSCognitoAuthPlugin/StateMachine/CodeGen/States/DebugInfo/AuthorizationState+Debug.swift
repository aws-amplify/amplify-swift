//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension AuthorizationState {
    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["AuthorizationState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [:]
        case .configured:
            additionalMetadataDictionary = [:]
        case .fetchingAuthSession:
            additionalMetadataDictionary = [:]
        case .sessionEstablished:
            additionalMetadataDictionary = [:]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }
}

