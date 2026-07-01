//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(IOKit)
import IOKit
#endif

/// Provides device metadata for event enrichment.
///
/// Implement this to supply custom device information. The default
/// ``PlatformDeviceMetadataProvider`` uses the same system APIs as the
/// Pinpoint analytics plugin.
protocol DeviceMetadataProvider: Sendable {
    /// Returns device metadata for the current platform.
    @MainActor func getDeviceMetadata() -> DeviceMetadata
}

/// Default ``DeviceMetadataProvider`` aligned with the Pinpoint plugin's
/// device information gathering (uses UIDevice/WKInterfaceDevice/IOKit).
struct PlatformDeviceMetadataProvider: DeviceMetadataProvider {
    init() {}

    @MainActor
    func getDeviceMetadata() -> DeviceMetadata {
        let os = operatingSystem()
        return DeviceMetadata(
            platform: os.name,
            platformVersion: os.version,
            manufacturer: "Apple",
            model: model(),
            locale: Locale.current.identifier
        )
    }

    @MainActor
    private func operatingSystem() -> (name: String, version: String) {
        #if canImport(WatchKit)
        let device = WKInterfaceDevice.current()
        return (name: device.systemName, version: device.systemVersion)
        #elseif canImport(UIKit)
        let device = UIDevice.current
        return (name: device.systemName, version: device.systemVersion)
        #else
        return (
            name: "macOS",
            version: ProcessInfo.processInfo.operatingSystemVersionString
        )
        #endif
    }

    @MainActor
    private func model() -> String {
        #if canImport(WatchKit)
        return WKInterfaceDevice.current().model
        #elseif canImport(UIKit)
        return UIDevice.current.model
        #elseif canImport(IOKit)
        return ioKitValue(forKey: "model") ?? "Mac"
        #else
        return "Mac"
        #endif
    }

    #if canImport(IOKit)
    private func ioKitValue(forKey key: String) -> String? {
        let service = IOServiceGetMatchingService(
            kIOMasterPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        defer { IOObjectRelease(service) }
        guard let data = IORegistryEntryCreateCFProperty(
            service, key as CFString, kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
    }
    #endif
}
