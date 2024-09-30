//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(FileBasedConfig)
public struct FileBasedConfigurationKey: RawRepresentable, ExpressibleByStringLiteral {
    public typealias RawValue = String
    public typealias StringLiteralType = String
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

@_spi(FileBasedConfig)
public extension FileBasedConfigurationKey {
    static var region: Self { "region" }
}
