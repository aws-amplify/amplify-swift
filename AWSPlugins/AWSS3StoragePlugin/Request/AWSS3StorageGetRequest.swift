//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// TODO: struct
public struct AWSS3StorageGetRequest {
    let bucket: String
    private let accessLevel: AccessLevel?
    private let _key: String
    let fileURL: URL?
    let expires: Int?

    init(builder: Builder) {
        self.bucket = builder.bucket
        self.accessLevel = builder.accessLevel
        self._key = builder.key
        self.fileURL = builder.fileURL
        self.expires = builder.expires
    }

    var key: String {
        // TODO: integrate with AWSMobileClient

        // Do we take a dependency on a singleton here? or take it somewhere else .. in the actual call.

        // Credentials.identitiyId

        // public
        // "public/{key}"
        // private
        // "private/{identityId}/{key}
        // protected
        // "protected/{identityId}/{key}"

        // also to leverage custom prefix variable

        if let accessLevel = accessLevel {
            return accessLevel.rawValue + "/" + _key
        } else {
            return _key
        }
    }

    // specific validation
    func validate() -> StorageGetError? {
        // validate things like customPrefix was passed in but is empty string
        // validate things like key passed in but is empty string
        // any way to validate fileURL ?
        // validate that it is not Both getURL and download to file scenario.
        return nil
    }

    // TODO: probably can turn to struct
    class Builder {
        let bucket: String
        private(set) var accessLevel: AccessLevel?
        let key: String
        private(set) var fileURL: URL?
        private(set) var expires: Int?

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

        func expires(_ expires: Int) -> Builder {
            self.expires = expires
            return self
        }

        func build() -> AWSS3StorageGetRequest {
            return AWSS3StorageGetRequest(builder: self)
        }
    }
}
