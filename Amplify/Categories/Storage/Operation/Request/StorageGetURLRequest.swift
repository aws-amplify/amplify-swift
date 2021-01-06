//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageGetURLRequest: AmplifyOperationRequest {
    /// The unique identifier for the object in storage
    public let key: String

    /// Options to adjust the behavior of this request, including plugin-options
    public let options: Options

    public init(key: String, options: Options) {
        self.key = key
        self.options = options
    }
}

public extension StorageGetURLRequest {
    /// Options to adjust the behavior of this request, including plugin-options
    struct Options {
        /// The default amount of time before the URL expires is 18000 seconds, or 5 hours.
        public static let defaultExpireInSeconds = 18_000

        /// Access level of the storage system. Defaults to `public`
        public let accessLevel: StorageAccessLevel

        /// Target user to apply the action on.
        public let targetIdentityId: String?

        /// Number of seconds before the URL expires. Defaults to `defaultExpireInSeconds`
        public let expires: Int

        /// Extra plugin specific options, only used in special circumstances when the existing options do not provide
        /// a way to utilize the underlying storage system's functionality. See plugin documentation for expected
        /// key/values
        public let pluginOptions: Any?

        public init(accessLevel: StorageAccessLevel = .guest,
                    targetIdentityId: String? = nil,
                    expires: Int = Options.defaultExpireInSeconds,
                    pluginOptions: Any? = nil) {
            self.accessLevel = accessLevel
            self.targetIdentityId = targetIdentityId
            self.expires = expires
            self.pluginOptions = pluginOptions
        }
    }
}
