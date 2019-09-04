//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageRemoveRequest {
    let bucket: String
    let accessLevel: AccessLevel
    let key: String

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self.key = builder.key
    }

    func getFinalKey(identity: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            return accessLevel.rawValue + "/" + identity + "/" + key
        }

        return accessLevel.rawValue + "/" + key
    }

    func validate() -> StorageRemoveError? {
        if bucket.isEmpty {
            return StorageRemoveError.unknown("bucket is empty", "bucket is empty")
        }

        if key.isEmpty {
            return StorageRemoveError.unknown("key is empty", "key is empty")
        }

        return nil
    }

    public class Builder {
        let bucket: String
        let accessLevel: AccessLevel
        let key: String

        init(bucket: String, key: String, accessLevel: AccessLevel) {
            self.bucket = bucket
            self.key = key
            self.accessLevel = accessLevel
        }

        func build() -> AWSS3StorageRemoveRequest {
            return AWSS3StorageRemoveRequest(builder: self)
        }
    }
}
