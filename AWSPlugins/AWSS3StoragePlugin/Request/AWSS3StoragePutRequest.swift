//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StoragePutRequest {
    let bucket: String
    let accessLevel: AccessLevel
    let key: String
    let data: Data?
    let fileURL: URL?
    let contentType: String?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self.key = builder.key
        self.data = builder.data
        self.fileURL = builder.fileURL
        self.contentType = builder.contentType
    }

    func getFinalKey(identity: String) -> String {
        if accessLevel == .Private || accessLevel == .Protected {
            return accessLevel.rawValue + "/" + identity + "/" + key
        }

        return accessLevel.rawValue + "/" + key
    }

    func validate() -> StoragePutError? {
        if let _ = data, let _ = fileURL {
            return StoragePutError.unknown("Both data and local", "was specified")
        }
        // return StorageGetError.unknown("error", "error")
        return nil
    }
    
    public class Builder {
        let bucket: String
        let accessLevel: AccessLevel
        let key: String
        private(set) var data: Data?
        private(set) var fileURL: URL?
        private(set) var contentType: String?

        init(bucket: String, key: String, accessLevel: AccessLevel) {
            self.bucket = bucket
            self.key = key
            self.accessLevel = accessLevel
        }

        func data(_ data: Data) -> Builder {
            self.data = data
            return self
        }

        func fileURL(_ fileURL: URL) -> Builder {
            self.fileURL = fileURL
            return self
        }

        func contentType(_ contentType: String) -> Builder {
            self.contentType = contentType
            return self
        }

        func build() -> AWSS3StoragePutRequest {
            return AWSS3StoragePutRequest(builder: self)
        }
    }
}
