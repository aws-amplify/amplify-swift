//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CredentialStoreState {
    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["CredentialStoreState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [:]
        case .migratingLegacyStore:
            additionalMetadataDictionary = [:]
        case .loadingStoredCredentials:
            additionalMetadataDictionary = [:]
        case .clearingCredentials:
            additionalMetadataDictionary = [:]
        case .storingCredentials:
            additionalMetadataDictionary = [:]
        case .idle:
            additionalMetadataDictionary = [:]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }
}
