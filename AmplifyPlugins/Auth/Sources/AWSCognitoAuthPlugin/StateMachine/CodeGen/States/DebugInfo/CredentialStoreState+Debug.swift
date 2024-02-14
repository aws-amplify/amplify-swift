//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CredentialStoreState: CustomDebugStringConvertible {
    var debugDictionary: [String: Any] {
        let additionalMetadataDictionary: [String: Any]

        switch self {
        case .notConfigured,
                .migratingLegacyStore,
                .loadingStoredCredentials,
                .storingCredentials,
                .clearingCredentials,
                .idle:
            additionalMetadataDictionary = [:]
        case .clearedCredential(let dataType):
            additionalMetadataDictionary = [
                "clearedDataType": dataType
            ]
        case .success(let data):
            additionalMetadataDictionary = [
                "savedData": data
            ]
        case .error(let error):
            additionalMetadataDictionary = [
                "errorType": error
            ]
        }
        return [type: additionalMetadataDictionary]
    }

    var debugDescription: String {
        return (debugDictionary as AnyObject).description
    }

}
