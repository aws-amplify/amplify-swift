//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(FileBasedConfig) import AWSSDKCommon

enum AppIDConfig {

    /// Determines the app ID to be used from the given config, if any.
    /// - Parameters:
    ///   - configValue: The app ID passed at client construction, or `nil` if none was passed.
    ///   - profileName: The profile name passed at client construction.  If `nil` is passed, the SDK will resolve the profile to be used.
    ///   - fileBasedConfig: The file-based config from which to load configuration, if needed.
    /// - Returns: The app ID that was resolved, or `nil` if none was resolved.
    static func appID(
        configValue: String?,
        profileName: String?,
        fileBasedConfig: FileBasedConfiguration
    ) -> String? {
        return FieldResolver(
            configValue: configValue,
            envVarName: "AWS_SDK_UA_APP_ID",
            configFieldName: "sdk_ua_app_id",
            fileBasedConfig: fileBasedConfig,
            profileName: profileName,
            converter: { $0.isEmpty ? nil : $0 }
        ).value
    }
}
