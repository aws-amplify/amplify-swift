//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(FileBasedConfig) public typealias FileBasedConfiguration = FileBasedConfigurationSectionProviding
@_spi(FileBasedConfig) public typealias FileBasedConfigurationSection = FileBasedConfigurationPropertyProviding
@_spi(FileBasedConfig) public typealias FileBasedConfigurationSubsection = FileBasedConfigurationValueProviding

@_spi(FileBasedConfig)
public enum FileBasedConfigurationSectionType {
    case profile
    case ssoSession
}

@_spi(FileBasedConfig)
public struct FileBasedConfigurationSources: Hashable {
    let configPath: String
    let credentialPath: String
}

@_spi(FileBasedConfig)
public typealias FileBasedConfigurationProviding = (
    _ configFilePath: String?,
    _ credentialsFilePath: String?
) async throws -> FileBasedConfigurationSectionProviding?

@_spi(FileBasedConfig)
public enum FileBasedConfigurationProperty {
    case string(String)
    case subsection(FileBasedConfigurationSubsection)
}

@_spi(FileBasedConfig)
public protocol FileBasedConfigurationSectionProviding {
    func section(for name: String, type: FileBasedConfigurationSectionType) -> FileBasedConfigurationSection?
}

@_spi(FileBasedConfig)
public extension FileBasedConfigurationSectionProviding {
    func section(for name: String) -> FileBasedConfigurationSection? {
        section(for: name, type: .profile)
    }
}

@_spi(FileBasedConfig)
public protocol FileBasedConfigurationPropertyProviding {
    func property(for name: FileBasedConfigurationKey) -> FileBasedConfigurationProperty?
}

@_spi(FileBasedConfig)
public protocol FileBasedConfigurationValueProviding {
    func value(for name: FileBasedConfigurationKey) -> String?
}

@_spi(FileBasedConfig)
public extension FileBasedConfigurationPropertyProviding {
    func string(for name: FileBasedConfigurationKey) -> String? {
        guard let value = property(for: name) else { return nil }
        switch value {
        case let .string(string):
            return string
        case .subsection:
            return nil
        }
    }

    func subproperties(for name: FileBasedConfigurationKey) -> FileBasedConfigurationSubsection? {
        guard let value = property(for: name) else { return nil }
        switch value {
        case .string:
            return nil
        case let .subsection(subsection):
            return subsection
        }
    }
}
