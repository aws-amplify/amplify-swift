//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Plugin specific configuration
///
/// - Tag: AWSS3StoragePluginConfiguration
public struct AWSS3StoragePluginConfiguration {

    /// - Tag: AWSS3StoragePluginConfiguration.prefixResolver
    @available(*, deprecated)
    public let prefixResolver: AWSS3PluginPrefixResolver?

    /// Default strategy for cancelling uploads when progress stops advancing.
    /// Override per upload with ``StorageUploadFileRequest/Options/progressStallTimeout`` or
    /// ``StorageUploadDataRequest/Options/progressStallTimeout``.
    public let progressStallTimeout: ProgressStallTimeout

    /// - Tag: AWSS3StoragePluginConfiguration.init
    /// - Parameters:
    ///   - prefixResolver: Deprecated. Use `StoragePath` instead.
    ///   - progressStallTimeout: Stall detection strategy. Default is ``ProgressStallTimeout/disabled``.
    public init(prefixResolver: AWSS3PluginPrefixResolver? = nil, progressStallTimeout: ProgressStallTimeout = .disabled) {
        self.prefixResolver = prefixResolver
        self.progressStallTimeout = progressStallTimeout
    }

    /// Resolves stall timeout seconds for an upload: per-operation override when non-`nil`, otherwise plugin default.
    func resolvedStallTimeoutSeconds(operationOverride: ProgressStallTimeout?) -> TimeInterval {
        (operationOverride ?? progressStallTimeout).secondsForStallTimer
    }

    /// - Tag: AWSS3StoragePluginConfiguration.prefixResolverFunc
    @available(*, deprecated, message: "Use `StoragePath` instead")
    public static func prefixResolver(
        _ prefixResolver: AWSS3PluginPrefixResolver) -> AWSS3StoragePluginConfiguration {
        .init(prefixResolver: prefixResolver)
    }
}
