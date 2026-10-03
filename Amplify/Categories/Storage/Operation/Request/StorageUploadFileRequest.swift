//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents an **file** upload request initiated by an implementation of the
/// [StorageCategoryPlugin](x-source-tag://StorageCategoryPlugin) protocol.
///
/// - Tag: StorageUploadFileRequest
public struct StorageUploadFileRequest: AmplifyOperationRequest {

    /// The path for the object in storage
    ///
    /// - Tag: StorageDownloadFileRequest.path
    public let path: (any StoragePath)?

    /// The unique identifier for the object in storage
    /// - Tag: StorageUploadFileRequest.key
    @available(*, deprecated, message: "Use `path` instead of `key`")
    public var key: String { legacyKey }
    package let legacyKey: String

    /// The file to be uploaded
    /// - Tag: StorageUploadFileRequest.local
    public let local: URL

    /// Options to adjust the behavior of this request, including plugin-options
    /// - Tag: StorageUploadFileRequest.options
    public let options: Options

    /// - Tag: StorageUploadFileRequest.init
    @available(*, deprecated, message: "Use init(path:local:options)")
    public init(key: String, local: URL, options: Options) {
        self.legacyKey = key
        self.local = local
        self.options = options
        self.path = nil
    }

    public init(path: any StoragePath, local: URL, options: Options) {
        self.legacyKey = ""
        self.local = local
        self.options = options
        self.path = path
    }
}

public extension StorageUploadFileRequest {

    /// Options to adjust the behavior of this request, including plugin-options
    ///
    /// - Tag: StorageUploadFileRequestOptions
    struct Options {

        /// Access level of the storage system. Defaults to `public`
        ///
        /// - Tag: StorageUploadFileRequestOptions.accessLevel
        @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
        public var accessLevel: StorageAccessLevel { .init(legacyAccessLevel) }
        package let legacyAccessLevel: LegacyStorageAccessLevel

        /// Target user to apply the action on.
        ///
        /// - Tag: StorageUploadFileRequestOptions.targetIdentityId
        @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
        public var targetIdentityId: String? { legacyTargetIdentityId }
        package let legacyTargetIdentityId: String?

        /// Metadata for the object to store
        ///
        /// - Tag: StorageUploadFileRequestOptions.metadata
        public let metadata: [String: String]?

        /// A specific Storage Bucket to upload the file. Defaults to `nil`, in which case the default one will be used.
        ///
        /// - Tag: StorageUploadFileRequestOptions.bucket
        public let bucket: (any StorageBucket)?

        /// The standard MIME type describing the format of the object to store
        ///
        /// - Tag: StorageUploadFileRequestOptions.contentType
        public let contentType: String?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        ///
        /// - Tag: StorageUploadFileRequestOptions.pluginOptions
        public let pluginOptions: Any?

        /// Override the storage plugin's default progress stall timeout for this upload only. `nil` uses the plugin default.
        public let progressStallTimeout: ProgressStallTimeout?

        /// - Tag: StorageUploadFileRequestOptions.init
        @available(*, deprecated, message: "Use init(metadata:contentType:pluginOptions)")
        public init(
            accessLevel: StorageAccessLevel = .guest,
            targetIdentityId: String? = nil,
            metadata: [String: String]? = nil,
            contentType: String? = nil,
            pluginOptions: Any? = nil,
            progressStallTimeout: ProgressStallTimeout? = nil
        ) {
            self.legacyAccessLevel = accessLevel.legacyValue
            self.legacyTargetIdentityId = targetIdentityId
            self.metadata = metadata
            self.bucket = nil
            self.contentType = contentType
            self.pluginOptions = pluginOptions
            self.progressStallTimeout = progressStallTimeout
        }

        /// - Tag: StorageUploadFileRequestOptions.init
        public init(
            metadata: [String: String]? = nil,
            contentType: String? = nil,
            pluginOptions: Any? = nil,
            progressStallTimeout: ProgressStallTimeout? = nil
        ) {
            self.legacyAccessLevel = .guest
            self.legacyTargetIdentityId = nil
            self.metadata = metadata
            self.bucket = nil
            self.contentType = contentType
            self.pluginOptions = pluginOptions
            self.progressStallTimeout = progressStallTimeout
        }

        /// - Tag: StorageUploadFileRequestOptions.init
        public init(
            metadata: [String: String]? = nil,
            bucket: some StorageBucket,
            contentType: String? = nil,
            pluginOptions: Any? = nil,
            progressStallTimeout: ProgressStallTimeout? = nil
        ) {
            self.legacyAccessLevel = .guest
            self.legacyTargetIdentityId = nil
            self.metadata = metadata
            self.bucket = bucket
            self.contentType = contentType
            self.pluginOptions = pluginOptions
            self.progressStallTimeout = progressStallTimeout
        }
    }
}

extension StorageUploadFileRequest.Options: @unchecked Sendable { }
