//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
}

extension StorageListResult {

    public struct Item {

        /// The unique identifier of the object in storage.
        public let key: String

        /// Size in bytes of the object
        public let size: Int?

        /// The date the Object was Last Modified
        public let lastModified: Date?

        /// The entity tag is an MD5 hash of the object.
        /// ETag reflects only changes to the contents of an object, not its metadata.
        public let eTag: String?

        /// Additional results specific to the plugin.
        public let pluginResults: Any?

        public init(key: String,
                    size: Int? = nil,
                    eTag: String? = nil,
                    lastModified: Date? = nil,
                    pluginResults: Any? = nil) {
            self.key = key
            self.size = size
            self.eTag = eTag
            self.lastModified = lastModified
            self.pluginResults  = pluginResults
        }
    }
}
