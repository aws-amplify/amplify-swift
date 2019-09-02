//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StorageGetRequest {
    let bucket: String
    private let accessLevel: AccessLevel
    private let key: String
    let fileURL: URL?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self.key = builder.key
        self.fileURL = builder.fileURL
    }

    func getFinalKey(identity: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            return accessLevel.rawValue + "/" + identity + "/" + key
        }

        return accessLevel.rawValue + "/" + key
    }

    func validate() -> StorageGetError? {
        // return StorageGetError.unknown("error", "error")
        return nil
    }

    class Builder {
        let bucket: String
        let accessLevel: AccessLevel
        let key: String
        private(set) var fileURL: URL?

        init(bucket: String, key: String, accessLevel: AccessLevel) {
            self.bucket = bucket
            self.key = key
            self.accessLevel = accessLevel
        }

        func fileURL(_ fileURL: URL) -> Builder {
            self.fileURL = fileURL
            return self
        }

        func build() -> AWSS3StorageGetRequest {
            return AWSS3StorageGetRequest(builder: self)
        }
    }
}
