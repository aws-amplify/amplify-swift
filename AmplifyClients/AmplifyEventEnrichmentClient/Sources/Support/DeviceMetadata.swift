//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Device-level metadata stamped on every enriched event.
public struct DeviceMetadata: Sendable {
    /// Platform name (e.g., "iOS", "macOS").
    public let platform: String?

    /// Platform OS version.
    public let platformVersion: String?

    /// Device manufacturer (e.g., "Apple").
    public let manufacturer: String?

    /// Device model (e.g., "iPhone15,2").
    public let model: String?

    /// Device locale code (e.g., "en_US").
    public let locale: String?

    public init(
        platform: String? = nil,
        platformVersion: String? = nil,
        manufacturer: String? = nil,
        model: String? = nil,
        locale: String? = nil
    ) {
        self.platform = platform
        self.platformVersion = platformVersion
        self.manufacturer = manufacturer
        self.model = model
        self.locale = locale
    }
}
