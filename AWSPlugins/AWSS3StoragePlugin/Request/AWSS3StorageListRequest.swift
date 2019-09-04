//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageListRequest {
    let bucket: String
    let accessLevel: AccessLevel
    private let prefix: String?
    private let limit: Int?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self.prefix = builder.prefix
        self.limit = builder.limit
    }

    func getFinalPrefix(identity: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            if let prefix = prefix {
                return accessLevel.rawValue + "/" + identity + "/" + prefix
            }

            return accessLevel.rawValue + "/" + identity + "/"
        }

        return accessLevel.rawValue + "/"
    }

    func validate() -> StorageListError? {
        if bucket.isEmpty {
            return StorageListError.unknown("bucket is empty", "bucket is empty")
        }

        if let prefix = prefix {
            if prefix.isEmpty {
                return StorageListError.unknown("prefix is specified but is empty", "empty")
            }
        }
        
        return nil
    }

    public class Builder {
        let bucket: String
        let accessLevel: AccessLevel
        private(set) var prefix: String?
        private(set) var limit: Int?

        init(bucket: String, accessLevel: AccessLevel) {
            self.bucket = bucket
            self.accessLevel = accessLevel
        }

        func limit(_ limit: Int) -> Builder {
            self.limit =  limit
            return self
        }

        func prefix(_ prefix: String) -> Builder {
            self.prefix = prefix
            return self
        }

        func build() -> AWSS3StorageListRequest {
            return AWSS3StorageListRequest(builder: self)
        }
    }
}
