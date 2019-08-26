//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSS3StorageGetUrlRequest {
    let bucket: String
    private let accessLevel: AccessLevel?
    private let _key: String
    let expires: Int?
    
    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self._key = builder.key
        self.expires = builder.expires
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
        private(set) var expires: Int?
        
        init(bucket: String, key: String) {
            self.bucket = bucket
            self.key = key
        }
        
        func accessLevel(_ accessLevel: AccessLevel) -> Builder {
            self.accessLevel = accessLevel
            return self
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
