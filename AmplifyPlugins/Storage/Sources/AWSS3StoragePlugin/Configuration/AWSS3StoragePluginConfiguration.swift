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
    public let prefixResolver: AWSS3PluginPrefixResolver?

    /// - Tag: AWSS3StoragePluginConfiguration.init
    public init(prefixResolver: AWSS3PluginPrefixResolver? = nil) {
        self.prefixResolver = prefixResolver
    }

    /// - Tag: AWSS3StoragePluginConfiguration.prefixResolverFunc
    public static func prefixResolver(
        _ prefixResolver: AWSS3PluginPrefixResolver) -> AWSS3StoragePluginConfiguration {
        .init(prefixResolver: prefixResolver)
    }
}
