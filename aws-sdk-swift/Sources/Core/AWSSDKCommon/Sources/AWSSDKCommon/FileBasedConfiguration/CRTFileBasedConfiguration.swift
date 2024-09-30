//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

@_spi(FileBasedConfig) public typealias CRTFileBasedConfiguration =
    AwsCommonRuntimeKit.FileBasedConfiguration
@_spi(FileBasedConfig) public typealias CRTFileBasedConfigurationSection =
    AwsCommonRuntimeKit.FileBasedConfiguration.Section
@_spi(FileBasedConfig) public typealias CRTFileBasedConfigurationSectionType =
    AwsCommonRuntimeKit.FileBasedConfiguration.SectionType
@_spi(FileBasedConfig) public typealias CRTFileBasedConfigurationProperty =
    AwsCommonRuntimeKit.FileBasedConfiguration.Section.Property

@_spi(FileBasedConfig)
extension CRTFileBasedConfigurationSectionType {
    init(_ type: FileBasedConfigurationSectionType) {
        switch type {
        case .profile:
            self = .profile
        case .ssoSession:
            self = .ssoSession
        }
    }
}

@_spi(FileBasedConfig)
extension CRTFileBasedConfiguration: FileBasedConfiguration {
    public static func make(
        configFilePath: String? = nil,
        credentialsFilePath: String? = nil
    ) throws -> CRTFileBasedConfiguration {
        let configFilePath = try configFilePath ?? CRTFileBasedConfiguration.resolveConfigPath(sourceType: .config)
        let credentialsFilePath = try credentialsFilePath ??
            CRTFileBasedConfiguration.resolveConfigPath(sourceType: .credentials)
        return try CRTFileBasedConfiguration(configFilePath: configFilePath, credentialsFilePath: credentialsFilePath)
    }

    public static func makeAsync(
        configFilePath: String? = nil,
        credentialsFilePath: String? = nil
    ) async throws -> CRTFileBasedConfiguration {
        let task = Task {
            try CRTFileBasedConfiguration.make(
                configFilePath: configFilePath,
                credentialsFilePath: credentialsFilePath
            )
        }
        return try await task.value
    }

    public func section(
        for name: String,
        type: FileBasedConfigurationSectionType
    ) -> FileBasedConfigurationPropertyProviding? {
        self.getSection(name: name, sectionType: .init(type))
    }
}

@_spi(FileBasedConfig)
extension CRTFileBasedConfigurationSection: FileBasedConfigurationSection {
    public func property(for name: FileBasedConfigurationKey) -> FileBasedConfigurationProperty? {
        guard let property = getProperty(name: name.rawValue) else { return nil }
        if property.subPropertyCount > 0 {
            return .subsection(property)
        } else {
            return .string(property.value)
        }
    }
}

@_spi(FileBasedConfig)
extension CRTFileBasedConfigurationProperty: FileBasedConfigurationSubsection {
    public func value(for name: FileBasedConfigurationKey) -> String? {
        self.getSubProperty(name: name.rawValue)
    }
}
