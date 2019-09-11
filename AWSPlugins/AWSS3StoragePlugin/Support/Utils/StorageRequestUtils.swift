//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class StorageRequestUtils {
    static let metadataKeyPrefix = "x-amz-meta-"

    static func getServiceKey(accessLevel: StorageAccessLevel,
                              identityId: String,
                              key: String) -> String {

        return getServiceKey(accessLevel: accessLevel, identityId: identityId, targetIdentityId: nil, key: key)
    }

    static func getServiceKey(accessLevel: StorageAccessLevel,
                              identityId: String,
                              targetIdentityId: String?,
                              key: String) -> String {

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

    static func validateTargetIdentityId(_ targetIdentityId: String?,
                                         accessLevel: StorageAccessLevel) -> StorageErrorString? {
        if let targetIdentityId = targetIdentityId {
            if targetIdentityId.isEmpty {
                return StorageErrorConstants.identityIdIsEmpty
            }

            if accessLevel == .private {
                return StorageErrorConstants.privateWithTarget
            }
        }

        return nil
    }

    static func validateKey(_ key: String) -> StorageErrorString? {
        if key.isEmpty {
            return StorageErrorConstants.keyIsEmpty
        }

        return nil
    }

    static func validate(_ storageGetDestination: StorageGetDestination) -> StorageErrorString? {
        switch storageGetDestination {
        case .data:
            break
        case .file:
            break
        case .url(let expires):
            if let expires = expires {
                if expires <= 0 {
                    return StorageErrorConstants.expiresIsInvalid
                }
            }
        }

        return nil
    }

    static func validatePath(_ path: String?) -> StorageErrorString? {
        if let path = path {
            if path.isEmpty {
                return StorageErrorConstants.pathIsEmpty
            }
        }

        return nil
    }

    static func validateContentType(_ contentType: String?) -> StorageErrorString? {
        if let contentType = contentType {
            if contentType.isEmpty {
                return StorageErrorConstants.contentTypeIsEmpty
            }
            // TODO content type validation
        }

        return nil
    }

    static func validateMetadata(_ metadata: [String: String]?) -> StorageErrorString? {
        if let metadata = metadata {
            for (key, value) in metadata {
                if key != key.lowercased() {
                    return StorageErrorConstants.metadataKeysInvalid
                }
                // TODO: validate that metadata values are within a certain size.
                // https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html#object-metadata 2KB
            }
        }

        return nil
    }

    // TODO: clean up
    static func isLargeUpload(_ uploadSource: UploadSource) -> Bool {
        let sizeThreshold = 10000000 // 10MB
        var isLargeUpload = false
        switch uploadSource {
        case .file(let file):
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: file.path)
                if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    print("Got file size: \(fileSize)")
                    if fileSize > sizeThreshold {
                        isLargeUpload = true
                    }
                }
            } catch {
                print("ErrorGettingFileSize: \(error)")
            }
        case .data(let data):
            let dataCount = data.count
            print("Got data size: \(dataCount)")
            if dataCount > sizeThreshold { // 10000000 = 10 MB
                isLargeUpload = true
            }
        }

        return isLargeUpload
    }
}
