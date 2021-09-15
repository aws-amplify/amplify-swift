//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension StorageRequestUtils {
    // MARK: Getter methods

    static func getAccessLevelPrefix(accessLevel: StorageAccessLevel,
                                     identityId: String,
                                     targetIdentityId: String?) -> String {

        let targetIdentityId = targetIdentityId ?? identityId

        if accessLevel == .private || accessLevel == .protected {

            return accessLevel.serviceAccessPrefix + "/" + targetIdentityId + "/"
        }

        return accessLevel.serviceAccessPrefix + "/"
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

    static func getSize(_ file: URL) throws -> UInt64 {
        if let error = validateFileExists(file) {
            throw StorageError.localFileNotFound(error.errorDescription, error.recoverySuggestion)
        }

        do {
            let attributeOfItem = try FileManager.default.attributesOfItem(atPath: file.path)
            guard let fileSize = attributeOfItem[FileAttributeKey.size] as? UInt64 else {
                throw StorageError.unknown("Could not get size of file.")
            }

            return fileSize
        } catch {
            throw StorageError.unknown("Unexpected error occurred while retrieving attributes of file.", error)
        }
    }
}

extension StorageAccessLevel {
    /// Service Access Prefix.
    public var serviceAccessPrefix: String {
        switch self {
        case .guest:
            return "public"
        case .protected:
            return rawValue
        case .private:
            return rawValue
        }
    }
}
