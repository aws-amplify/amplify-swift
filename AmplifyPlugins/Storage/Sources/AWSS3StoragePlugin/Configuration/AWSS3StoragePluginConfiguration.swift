//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Plugin specific configuration
///
/// - Tag: AWSS3StoragePluginConfiguration
public struct AWSS3StoragePluginConfiguration {

    /// - Tag: AWSS3StoragePluginConfiguration.prefixResolver
    @available(*, deprecated)
    public let prefixResolver: AWSS3PluginPrefixResolver?

    /// If upload progress does not advance for this many seconds, the upload is cancelled. 0 = disabled.
    public let progressStallTimeoutInterval: TimeInterval

    /// - Tag: AWSS3StoragePluginConfiguration.init
    public init(prefixResolver: AWSS3PluginPrefixResolver? = nil, progressStallTimeoutInterval: TimeInterval = 0) {
        self.prefixResolver = prefixResolver
        self.progressStallTimeoutInterval = progressStallTimeoutInterval
    }

    /// - Tag: AWSS3StoragePluginConfiguration.prefixResolverFunc
    @available(*, deprecated, message: "Use `StoragePath` instead")
    public static func prefixResolver(
        _ prefixResolver: AWSS3PluginPrefixResolver) -> AWSS3StoragePluginConfiguration {
        .init(prefixResolver: prefixResolver)
    }
}
