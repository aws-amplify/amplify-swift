//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension FetchIdentityState {
    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["FetchIdentityState": type]
        var additionalMetadataDictionary: [String: Any] = [:]
        
        switch self {
        case .configuring:
            additionalMetadataDictionary = [:]
        case .fetching:
            additionalMetadataDictionary = [:]
        case .fetched:
            additionalMetadataDictionary = [:]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }
}

