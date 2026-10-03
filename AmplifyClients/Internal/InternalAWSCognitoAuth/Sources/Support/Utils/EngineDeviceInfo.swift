//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Note: It's important to check for WatchKit first because a stripped-down version of UIKit is also
// available on watchOS
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(IOKit)
import IOKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// The engine's copy of the members of `Amplify.DeviceInfo` (`Amplify/Core/Support/DeviceInfo.swift`)
/// that the engine reads: `name`, `hostName`, `model`, `operatingSystem`, `identifierForVendor` and
/// `screenBounds`. Each body, and each platform branch, is Amplify's.
///
/// These values reach Cognito: the confirmed device's name (`ConfirmDevice`) and the advanced security
/// fingerprint (`ASFDeviceInfo`). A drift would make Cognito see a new device, so a per-platform
/// differential test compares every member with `Amplify.DeviceInfo`.
@MainActor
package struct EngineDeviceInfo {

    private init() {}

    package static let current = EngineDeviceInfo()

    /// Returns the name of the host or device
    package var name: String {
    #if canImport(WatchKit)
        WKInterfaceDevice.current().name
    #elseif canImport(UIKit)
        UIDevice.current.name
    #else
        ProcessInfo.processInfo.hostName
    #endif
    }

    /// Returns the name of the host
    package var hostName: String {
        ProcessInfo.processInfo.hostName
    }

    /// Returns the name of the model of the device
    package var model: String {
    #if canImport(WatchKit)
        WKInterfaceDevice.current().model
    #elseif canImport(UIKit)
        UIDevice.current.model
    #elseif canImport(IOKit)
        value(forKey: "model") ?? "Mac"
    #else
        "Mac"
    #endif
    }

    /// Returns a tuple with the name of the operating system, e.g. "watchOS", "iOS", or "macOS" and its
    /// semantic version number
    package var operatingSystem: (name: String, version: String) {
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

    /// If available, returns the unique identifier for the device
    package var identifierForVendor: UUID? {
    #if canImport(WatchKit)
        WKInterfaceDevice.current().identifierForVendor
    #elseif canImport(UIKit)
        UIDevice.current.identifierForVendor
    #else
        nil
    #endif
    }

    /// Returns the bounding rect of the main screen of the device
    package var screenBounds: CGRect {
    #if os(visionOS)
        .zero
    #elseif canImport(WatchKit)
        .zero
    #elseif canImport(UIKit)
        UIScreen.main.nativeBounds
    #elseif canImport(AppKit)
        NSScreen.main?.visibleFrame ?? .zero
    #endif
    }

#if canImport(IOKit)
    /// Amplify's lookup, with `kIOMainPortDefault` for the deprecated `kIOMasterPortDefault`. Both are
    /// the default main port (`0`).
    private func value(forKey key: String) -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }

        IOObjectRelease(service)
        return modelIdentifier
    }
#endif
}
