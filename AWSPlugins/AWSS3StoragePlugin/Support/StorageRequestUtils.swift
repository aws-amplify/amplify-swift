//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class StorageRequestUtils {
    public static func getServiceKey(accessLevel: StorageAccessLevel, identityId: String, key: String) -> String {
        return getAccessLevelPrefix(accessLevel: accessLevel, identityId: identityId) + key
    }

    public static func getAccessLevelPrefix(accessLevel: StorageAccessLevel, identityId: String) -> String {
        if accessLevel == .private || accessLevel == .protected {
            return accessLevel.rawValue + "/" + identityId + "/"
        }

        return accessLevel.rawValue + "/"
    }
}
