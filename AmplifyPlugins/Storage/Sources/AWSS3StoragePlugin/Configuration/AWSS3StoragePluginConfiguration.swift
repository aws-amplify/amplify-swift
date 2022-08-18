//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Plugin specific configuration
public struct AWSS3StoragePluginConfiguration {

    public let prefixResolver: AWSS3PluginPrefixResolver?

    public init(prefixResolver: AWSS3PluginPrefixResolver? = nil) {
        self.prefixResolver = prefixResolver
    }

    public static func prefixResolver(
        _ prefixResolver: AWSS3PluginPrefixResolver) -> AWSS3StoragePluginConfiguration {
        .init(prefixResolver: prefixResolver)
    }
}
