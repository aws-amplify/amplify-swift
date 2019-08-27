//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSS3StoragePutRequest {
    let bucket: String
    private let accessLevel: AccessLevel?
    private let _key: String
    let data: Data?
    let local: URL?
    let contentType: String?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self._key = builder.key
        self.data = builder.data
        self.local = builder.local
        self.contentType = builder.contentType
    }

    var key: String {
        if let accessLevel = accessLevel {
            return accessLevel.rawValue + "/" + _key
        } else {
            return _key
        }
    }

    class Builder {
        let bucket: String
        private(set) var accessLevel: AccessLevel?
        let key: String
        private(set) var data: Data?
        private(set) var local: URL?
        private(set) var contentType: String?

        init(bucket: String, key: String) {
            self.bucket = bucket
            self.key = key
        }

        func data(_ data: Data) -> Builder {
            self.data = data
            return self
        }

        func local(_ local: URL) -> Builder {
            self.local = local
            return self
        }
        func accessLevel(_ accessLevel: AccessLevel) -> Builder {
            self.accessLevel = accessLevel
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
