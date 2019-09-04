//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageGetUrlRequest {
    let bucket: String
    private let accessLevel: AccessLevel
    private let key: String
    let expires: Int?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self.key = builder.key
        self.expires = builder.expires
    }

    func getFinalKey(identity: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            return accessLevel.rawValue + "/" + identity + "/" + key
        }

        return accessLevel.rawValue + "/" + key
    }

    func validate() -> StorageGetUrlError? {
        if bucket.isEmpty {
            return StorageGetUrlError.unknown("bucket is empty", "bucket is empty")
        }

        if key.isEmpty {
            return StorageGetUrlError.unknown("key is empty", "key is empty")
        }

        return nil
    }

    public class Builder {
        let bucket: String
        let accessLevel: AccessLevel
        let key: String
        private(set) var expires: Int?

        init(bucket: String, key: String, accessLevel: AccessLevel) {
            self.bucket = bucket
            self.key = key
            self.accessLevel = accessLevel
        }

        func expires(_ expires: Int) -> Builder {
            self.expires = expires
            return self
        }

        func build() -> AWSS3StorageGetUrlRequest {
            return AWSS3StorageGetUrlRequest(builder: self)
        }
    }
}
