//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class StorageRequestUtils {
    static let metadataKeyPrefix = "x-amz-meta-"

    public static func getServiceKey(accessLevel: StorageAccessLevel, identityId: String, key: String) -> String {
        return getAccessLevelPrefix(accessLevel: accessLevel, identityId: identityId) + key
    }

    public static func getAccessLevelPrefix(accessLevel: StorageAccessLevel, identityId: String) -> String {
        if accessLevel == .private || accessLevel == .protected {
            return accessLevel.rawValue + "/" + identityId + "/"
        }

        return accessLevel.rawValue + "/"
    }

    public static func getServiceMetadata(_ metadata: [String: String]?) -> [String: String]? {
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
}
