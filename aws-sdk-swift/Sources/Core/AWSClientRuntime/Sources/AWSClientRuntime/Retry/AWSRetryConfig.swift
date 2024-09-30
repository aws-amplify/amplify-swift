//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetriesAPI.RetryStrategyOptions
@_spi(FileBasedConfig) import AWSSDKCommon

public enum AWSRetryConfig {

    /// Determines the retry mode to be used from the given config.  If none can be determined, `legacy` will be used as a default.
    /// - Parameters:
    ///   - configValue: The retry mode passed at client construction, or `nil` if none was passed.
    ///   - profileName: The profile name passed at client construction.  If `nil` is passed, the SDK will resolve the profile to be used.
    ///   - fileBasedConfig: The file-based config from which to load configuration, if needed.
    /// - Returns: The retry mode that was resolved.
    static func retryMode(
        configValue: AWSRetryMode?,
        profileName: String?,
        fileBasedConfig: FileBasedConfiguration
    ) -> AWSRetryMode {
        return FieldResolver(
            configValue: configValue,
            envVarName: "AWS_RETRY_MODE",
            configFieldName: "retry_mode",
            fileBasedConfig: fileBasedConfig,
            profileName: profileName,
            converter: { AWSRetryMode(rawValue: $0) }
        ).value ?? .legacy
    }

    /// Determines the max attempts (for retry purposes) to be used from the given config.  If none can be determined, `3` will be used as a default.
    ///
    /// Max attempts must be a positive, nonzero integer.
    /// - Parameters:
    ///   - configValue: The max attempts passed at client construction, or `nil` if none was passed.
    ///   - profileName: The profile name passed at client construction.  If `nil` is passed, the SDK will resolve the profile to be used.
    ///   - fileBasedConfig: The file-based config from which to load configuration, if needed.
    /// - Returns: The max attempts that was resolved.
    static func maxAttempts(
        configValue: Int?,
        profileName: String?,
        fileBasedConfig: FileBasedConfiguration
    ) -> Int {
        return FieldResolver(
            configValue: configValue,
            envVarName: "AWS_MAX_ATTEMPTS",
            configFieldName: "max_attempts",
            fileBasedConfig: fileBasedConfig,
            profileName: profileName,
            converter: { Int($0) }
        ).value ?? 3
    }
}
