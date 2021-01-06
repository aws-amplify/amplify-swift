//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageListRequest: AmplifyOperationRequest {
    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(options: Options) {
        self.options = options
    }
}

public extension StorageListRequest {
    /// Options to adjust the behavior of this request, including plugin-options
    struct Options {
        /// Access level of the storage system. Defaults to `public`
        public let accessLevel: StorageAccessLevel

        /// Target user to apply the action on
        public let targetIdentityId: String?

        /// Path to the keys
        public let path: String?

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(accessLevel: StorageAccessLevel = .guest,
                    targetIdentityId: String? = nil,
                    path: String? = nil,
                    pluginOptions: Any? = nil) {
            self.accessLevel = accessLevel
            self.targetIdentityId = targetIdentityId
            self.path = path
            self.pluginOptions = pluginOptions
        }
    }
}
