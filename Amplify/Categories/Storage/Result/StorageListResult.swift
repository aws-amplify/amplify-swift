//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents the output of a call to
/// [StorageCategoryBehavior.list](x-source-tag://StorageCategoryBehavior.list)
///
/// - Tag: StorageListResult
public struct StorageListResult {

    /// This is meant to be called by plugins implementing
    /// [StorageCategoryBehavior.list](x-source-tag://StorageCategoryBehavior.list).
    ///
    /// - Tag: StorageListResult.init
    public init(
        items: [Item],
        excludedSubpaths: [String] = [],
        nextToken: String? = nil
    ) {
        self.items = items
        self.excludedSubpaths = excludedSubpaths
        self.nextToken = nextToken
    }

    /// Array of Items in the Result
    ///
    /// - Tag: StorageListResult.items
    public var items: [Item]


    /// Array of excluded subpaths in the Result. 
    /// This field is only populated when [`StorageListRequest.Options.subpathStrategy`](x-source-tag://StorageListRequestOptions.subpathStragegy) is set to [`.exclude()`](x-source-tag://SubpathStrategy.exclude).
    ///
    /// - Tag: StorageListResult.excludedSubpaths
    public var excludedSubpaths: [String]

    /// Opaque string indicating the page offset at which to resume a listing. This value is usually copied to
    /// [StorageListRequestOptions.nextToken](x-source-tag://StorageListRequestOptions.nextToken).
    ///
    /// - SeeAlso:
    /// [StorageListRequestOptions.nextToken](x-source-tag://StorageListRequestOptions.nextToken)
    ///
    /// - Tag: StorageListResult.nextToken
    public let nextToken: String?
}

extension StorageListResult: Sendable { }

extension StorageListResult {

    /// - Tag: StorageListResultItem
    public struct Item {

        /// The path of the object in storage.
        ///
        /// - Tag: StorageListResultItem.path
        public let path: String

        /// The unique identifier of the object in storage.
        ///
        /// - Tag: StorageListResultItem.key
        @available(*, deprecated, message: "Use `path` instead.")
        public let key: String

        /// Size in bytes of the object
        ///
        /// - Tag: StorageListResultItem.size
        public let size: Int?

        /// The date the Object was Last Modified
        ///
        /// - Tag: StorageListResultItem.lastModified
        public let lastModified: Date?

        /// The entity tag is an MD5 hash of the object.
        /// ETag reflects only changes to the contents of an object, not its metadata.
        ///
        /// - Tag: StorageListResultItem.eTag
        public let eTag: String?

        /// Additional results specific to the plugin.
        ///
        /// - Tag: StorageListResultItem.pluginResults
        public let pluginResults: Any?

        /// This is meant to be called by plugins implementing
        /// [StorageCategoryBehavior.list](x-source-tag://StorageCategoryBehavior.list).
        ///
        /// - Tag: StorageListResultItem.init
        @available(*, deprecated, message: "Use init(path:size:lastModifiedDate:eTag:pluginResults)")
        public init(
            key: String,
            size: Int? = nil,
            eTag: String? = nil,
            lastModified: Date? = nil,
            pluginResults: Any? = nil
        ) {
            self.key = key
            self.size = size
            self.eTag = eTag
            self.lastModified = lastModified
            self.pluginResults  = pluginResults
            self.path = ""
        }

        public init(
            path: String,
            size: Int? = nil,
            eTag: String? = nil,
            lastModified: Date? = nil,
            pluginResults: Any? = nil
        ) {
            self.path = path
            self.key = path
            self.size = size
            self.eTag = eTag
            self.lastModified = lastModified
            self.pluginResults  = pluginResults
        }
    }
}

extension StorageListResult.Item: Sendable { }
