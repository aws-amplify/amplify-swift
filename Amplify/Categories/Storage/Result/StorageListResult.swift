//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageListResult {
    public init(items: [Item]) {
        self.items = items
    }

    // Array of Items in the Result
    public var items: [Item]

    public struct Item {

        /// The unique identifier of the object in storage.
        public let key: String

        /// The entity tag is an MD5 hash of the object.
        /// ETag reflects only changes to the contents of an object, not its metadata.
        public let eTag: String

        /// The date the Object was Last Modified
        public let lastModified: Date

        /// Size in bytes of the object
        public let size: Int

        public init(key: String, eTag: String, lastModified: Date, size: Int) {
            self.key = key
            self.eTag = eTag
            self.lastModified = lastModified
            self.size = size
        }
    }
}
