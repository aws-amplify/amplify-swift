//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class StorageRequestUtils {
    public static func getServiceKey(accessLevel: AccessLevel, identityId: String, key: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            return accessLevel.rawValue + "/" + identityId + "/" + key
        }

        return accessLevel.rawValue + "/" + key
    }

    public static func getServicePrefix(accessLevel: AccessLevel, identityId: String, prefix: String?) -> String {
        return getServiceKey(accessLevel: accessLevel, identityId: identityId, key: prefix ?? "")
    }
}
