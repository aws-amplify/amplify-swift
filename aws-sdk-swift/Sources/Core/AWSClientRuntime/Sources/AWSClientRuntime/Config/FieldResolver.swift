//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.ProcessInfo
@_spi(FileBasedConfig) import AWSSDKCommon

/// Resolves a configuration field for an AWS SDK feature.
struct FieldResolver<T> {
    let configValue: T?
    let envVarName: String?
    let configFieldName: String?
    let fileBasedConfig: FileBasedConfiguration
    let profileName: String?
    let converter: (String) -> T?

    init(configValue: T?,
         envVarName: String?,
         configFieldName: String?,
         fileBasedConfig: FileBasedConfiguration,
         profileName: String?,
         converter: @escaping (String) -> T?
    ) {
        self.configValue = configValue
        self.envVarName = envVarName
        self.configFieldName = configFieldName
        self.fileBasedConfig = fileBasedConfig
        self.profileName = profileName
        self.converter = converter
    }

    /// Resolves a configuration field for an AWS SDK feature.
    ///
    /// Resolves the field in the following order:
    /// - If `configValue` is provided, it is used.
    /// - If an environment var named `envVarName` is set, its value is used to create a value.
    /// - If a config field is set in the config file for the current profile, its value is used to create a value.
    /// - Finally, if none of the above yield a value, `nil` is returned.
    var value: T? {
        let env = ProcessInfo.processInfo.environment
        if let value = configValue {
            return value
        }
        if let envVarName = envVarName, let envValue = env[envVarName], let value = converter(envValue) {
            return value
        }
        if let configFieldName = configFieldName {
            let key = FileBasedConfigurationKey(rawValue: configFieldName)
            let envProfileName = env["AWS_PROFILE"]
            let sectionName = profileName ?? envProfileName ?? "default"
            if let configValue = fileBasedConfig.section(for: sectionName)?.string(for: key) {
                return converter(configValue)
            }
        }
        return nil
    }
}
