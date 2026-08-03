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
protocol DeviceMetadataProvider: Sendable {
    @MainActor func getDeviceMetadata() -> DeviceMetadata
}

/// Default ``DeviceMetadataProvider`` using UIDevice/WKInterfaceDevice/IOKit.
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

    /// Value reported when a platform API cannot supply real device metadata,
    /// rather than guessing a concrete platform or model name.
    private static let unknownValue = "unknown"

    @MainActor
    private func operatingSystem() -> (name: String, version: String) {
        #if canImport(WatchKit)
        return (
            name: WKInterfaceDevice.current().systemName,
            version: WKInterfaceDevice.current().systemVersion
        )
        #elseif canImport(UIKit)
        return (
            name: UIDevice.current.systemName,
            version: UIDevice.current.systemVersion
        )
        #else
        return (name: Self.platformName, version: Self.operatingSystemVersion)
        #endif
    }

    /// The platform name for targets that expose neither WatchKit nor UIKit.
    ///
    /// Resolved from the compile-time target rather than assumed to be macOS. Mac
    /// Catalyst also reaches this branch, as would any future Apple platform without
    /// UIKit, and reporting a hardcoded name there would mislabel the event.
    private static var platformName: String {
        #if os(macOS)
        return "macOS"
        #elseif os(visionOS)
        return "visionOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return unknownValue
        #endif
    }

    /// A dotted version string (for example `14.1` or `14.1.2`).
    ///
    /// Built from `operatingSystemVersion` rather than `operatingSystemVersionString`,
    /// which returns a display string like `Version 14.1 (Build 23B74)` and would not
    /// match the bare `17.0` shape that UIKit and WatchKit report.
    private static var operatingSystemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let base = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion == 0 ? base : "\(base).\(version.patchVersion)"
    }

    @MainActor
    private func model() -> String {
        #if canImport(WatchKit)
        return WKInterfaceDevice.current().model
        #elseif canImport(UIKit)
        return UIDevice.current.model
        #elseif canImport(IOKit)
        // Reachable on macOS and Mac Catalyst; the registry value is the real
        // identifier (for example `Mac14,9`), so fall back only when it is absent.
        return ioKitValue(forKey: "model") ?? Self.unknownValue
        #else
        return Self.unknownValue
        #endif
    }

    #if canImport(IOKit)
    private func ioKitValue(forKey key: String) -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
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
