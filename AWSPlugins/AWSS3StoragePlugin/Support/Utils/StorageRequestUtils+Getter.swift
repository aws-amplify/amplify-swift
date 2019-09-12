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
}
