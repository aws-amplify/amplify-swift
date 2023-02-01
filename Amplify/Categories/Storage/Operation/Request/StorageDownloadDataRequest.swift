//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageDownloadDataRequest: AmplifyOperationRequest {
    /// The unique identifier for the object in storage
    public let key: String

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(key: String, options: Options) {
        self.key = key
        self.options = options
    }
}

public extension StorageDownloadDataRequest {
    /// Options to adjust the behavior of this request, including plugin-options
    struct Options {
        /// Access level of the storage system. Defaults to `public`
        public let accessLevel: StorageAccessLevel

        /// Target user to apply the action on.
        public let targetIdentityId: String?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        // swiftlint:disable:next todo
        // TODO: transferAcceleration should be in pluginOptions
        // https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html

        public init(accessLevel: StorageAccessLevel = .guest,
                    targetIdentityId: String? = nil,
                    pluginOptions: Any? = nil) {
            self.accessLevel = accessLevel
            self.targetIdentityId = targetIdentityId
            self.pluginOptions = pluginOptions
        }
    }
}
