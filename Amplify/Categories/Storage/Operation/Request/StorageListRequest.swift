//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Represents a object listing request initiated by an implementation of the
/// [StorageCategoryPlugin](x-source-tag://StorageCategoryPlugin) protocol.
///
/// - Tag: StorageListRequest
public struct StorageListRequest: AmplifyOperationRequest {

    /// Options to adjust the behavior of this request, including plugin-options
    /// - Tag: StorageListRequest
    public let options: Options

    /// The unique path for the object in storage
    ///
    /// - Tag: StorageListRequest.path
    public let path: (any StoragePath)?

    /// - Tag: StorageListRequest.init
    @available(*, deprecated, message: "Use init(path:options)")
    public init(options: Options) {
        self.options = options
        self.path = nil
    }

    /// - Tag: StorageListRequest.init
    public init(path: any StoragePath, options: Options) {
        self.options = options
        self.path = path
    }
}

public extension StorageListRequest {

    /// Options available to callers of
    /// [StorageCategoryBehavior.list](x-source-tag://StorageCategoryBehavior.list).
    ///
    /// Tag: StorageListRequestOptions
    struct Options {

        /// Access level of the storage system. Defaults to `public`
        ///
        /// - Tag: StorageListRequestOptions.accessLevel
        @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
        public let accessLevel: StorageAccessLevel

        /// Target user to apply the action on
        ///
        /// - Tag: StorageListRequestOptions.targetIdentityId
        @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
        public let targetIdentityId: String?

        /// Path to the keys
        ///
        /// - Tag: StorageListRequestOptions.path
        @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
        public let path: String?

        /// The strategy to use when listing contents from subpaths. Defaults to [`.include`](x-source-tag://SubpathStrategy.include)
        ///
        /// - Tag: StorageListRequestOptions.subpathStrategy
        public let subpathStrategy: SubpathStrategy

        /// Number between 1 and 1,000 that indicates the limit of how many entries to fetch when
        /// retreiving file lists from the server.
        ///
        /// NOTE: Plugins may decide to throw or perform normalization when encoutering vaues outside
        ///       the specified range.
        ///
        /// - SeeAlso:
        /// [StorageListRequestOptions.nextToken](x-source-tag://StorageListRequestOptions.nextToken)
        /// [StorageListResult.nextToken](x-source-tag://StorageListResult.nextToken)
        ///
        /// - Tag: StorageListRequestOptions.pageSize
        public let pageSize: UInt

        /// A Storage Bucket that contains the objects to list. Defaults to `nil`, in which case the default one will be used.
        ///
        /// - Tag: StorageDownloadDataRequest.bucket
        public let bucket: (any StorageBucket)?

        /// Opaque string indicating the page offset at which to resume a listing. This is usually a copy of
        /// the value from [StorageListResult.nextToken](x-source-tag://StorageListResult.nextToken).
        ///
        /// - SeeAlso:
        /// [StorageListRequestOptions.pageSize](x-source-tag://StorageListRequestOptions.pageSize)
        /// [StorageListResult.nextToken](x-source-tag://StorageListResult.nextToken)
        ///
        /// - Tag: StorageListRequestOptions.nextToken
        public let nextToken: String?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        ///
        /// - Tag: StorageListRequestOptions.pluginOptions
        public let pluginOptions: Any?

        /// - Tag: StorageListRequestOptions.init
        public init(
            accessLevel: StorageAccessLevel = .guest,
            targetIdentityId: String? = nil,
            path: String? = nil,
            subpathStrategy: SubpathStrategy = .include,
            pageSize: UInt = 1000,
            nextToken: String? = nil,
            pluginOptions: Any? = nil
        ) {
            self.accessLevel = accessLevel
            self.targetIdentityId = targetIdentityId
            self.path = path
            self.subpathStrategy = subpathStrategy
            self.pageSize = pageSize
            self.bucket = nil
            self.nextToken = nextToken
            self.pluginOptions = pluginOptions
        }

        /// - Tag: StorageListRequestOptions.init
        public init(
            subpathStrategy: SubpathStrategy = .include,
            pageSize: UInt = 1000,
            bucket: some StorageBucket,
            nextToken: String? = nil,
            pluginOptions: Any? = nil
        ) {
            self.accessLevel = .guest
            self.targetIdentityId = nil
            self.path = nil
            self.subpathStrategy = subpathStrategy
            self.pageSize = pageSize
            self.bucket = bucket
            self.nextToken = nextToken
            self.pluginOptions = pluginOptions
        }
    }
}

public extension StorageListRequest.Options {
    /// Represents the strategy used when listing contents from subpaths relative to the given path.
    ///
    /// - Tag: StorageListRequestOptions.SubpathStrategy
    enum SubpathStrategy {
        /// Items from nested subpaths are included in the results
        ///
        /// - Tag: SubpathStrategy.include
        case include

        /// Items from nested subpaths are not included in the results. Their subpaths are instead grouped under [`StorageListResult.excludedSubpaths`](StorageListResult.excludedSubpaths).
        ///
        /// - Parameter delimitedBy: The delimiter used to determine subpaths. Defaults to `"/"`
        ///
        /// - SeeAlso: [`StorageListResult.excludedSubpaths`](x-source-tag://StorageListResult.excludedSubpaths)
        ///
        /// - Tag: SubpathStrategy.excludeWithDelimiter
        case exclude(delimitedBy: String = "/")

        /// Items from nested subpaths are not included in the results. Their subpaths are instead grouped under [`StorageListResult.excludedSubpaths`](StorageListResult.excludedSubpaths).
        ///
        /// - SeeAlso: [`StorageListResult.excludedSubpaths`](x-source-tag://StorageListResult.excludedSubpaths)
        ///
        /// - Tag: SubpathStrategy.exclude
        public static var exclude: SubpathStrategy {
            return .exclude()
        }
    }
}

extension StorageListRequest.Options: @unchecked Sendable { }
extension StorageListRequest.Options.SubpathStrategy: Sendable { }
