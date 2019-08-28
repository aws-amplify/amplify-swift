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
    private let accessLevel: AccessLevel?
    private let _prefix: String?
    let limit: Int?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self._prefix = builder.prefix
        self.limit = builder.limit
    }

    var prefix: String? {
        if let accessLevel = accessLevel, let prefix = _prefix {
            return accessLevel.rawValue + prefix
        } else if let accessLevel = accessLevel {
            return accessLevel.rawValue
        } else if let prefix = _prefix {
            return prefix
        }

        return nil
    }

    class Builder {
        let bucket: String
        private(set) var accessLevel: AccessLevel?
        private(set) var prefix: String?
        private(set) var limit: Int?

        init(bucket: String) {
            self.bucket = bucket
        }

        func accessLevel(_ accessLevel: AccessLevel) -> Builder {
            self.accessLevel = accessLevel
            return self
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
