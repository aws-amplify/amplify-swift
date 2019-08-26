//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSS3StorageGetRequest {
    let bucket: String
    private let accessLevel: AccessLevel?
    private let _key: String
    let fileURL: URL?
    
    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self._key = builder.key
        self.fileURL = builder.fileURL
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
        private(set) var fileURL: URL?
        
        init(bucket: String, key: String) {
            self.bucket = bucket
            self.key = key
        }
        
        func accessLevel(_ accessLevel: AccessLevel) -> Builder {
            self.accessLevel = accessLevel
            return self
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
