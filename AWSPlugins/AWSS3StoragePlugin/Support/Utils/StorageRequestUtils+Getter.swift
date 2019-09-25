//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageRequestUtils {
    // MARK: Getter methods

    static func getServiceKey(accessLevel: StorageAccessLevel,
                              identityId: String,
                              key: String,
                              targetIdentityId: String? = nil) -> String {

        return getAccessLevelPrefix(accessLevel: accessLevel,
                                    identityId: identityId,
                                    targetIdentityId: targetIdentityId) + key
    }

    static func getAccessLevelPrefix(accessLevel: StorageAccessLevel,
                                     identityId: String,
                                     targetIdentityId: String?) -> String {

        let targetIdentityId = targetIdentityId ?? identityId

        if accessLevel == .private || accessLevel == .protected {

            return accessLevel.rawValue + "/" + targetIdentityId + "/"
        }

        return accessLevel.rawValue + "/"
    }

    static func getServiceMetadata(_ metadata: [String: String]?) -> [String: String]? {
        guard let metadata = metadata else {
            return nil
        }
        var serviceMetadata: [String: String] = [:]
        for (key, value) in metadata {
            let serviceKey = metadataKeyPrefix + key
            serviceMetadata[serviceKey] = value
        }

        return serviceMetadata
    }

    static func getSize(_ uploadSource: UploadSource) -> Result<UInt64, StorageError> {
        switch uploadSource {
        case .file(let file):
            if let error = validateFileExists(file) {
                return .failure(StorageError.missingLocalFile(error.errorDescription, error.recoverySuggestion))
            }

            do {
                let attributeOfItem = try FileManager.default.attributesOfItem(atPath: file.path)
                guard let fileSize = attributeOfItem[FileAttributeKey.size] as? UInt64 else {
                    return .failure(StorageError.unknown("file Issue", "File Issue"))
                }

                return .success(fileSize)
            } catch {
                return .failure(StorageError.unknown("File issue", "file issue"))
            }

        case .data(let data):
            return .success(UInt64(data.count))
        }
    }
}
