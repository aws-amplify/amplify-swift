//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension CredentialStoreState {
    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["CredentialStoreState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [:]
        case .migratingLegacyStore(let authenticationConfiguration):
            additionalMetadataDictionary = [
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
            ]
        case .loadingStoredCredentials(let authenticationConfiguration):
            additionalMetadataDictionary = [
                "- AuthenticationConfiguration": authenticationConfiguration.debugDictionary,
            ]
        case .configuredCredentialStore:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }
}

