//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(WatchKit)
import WatchKit
#elseif canImport(IOKit)
import IOKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public struct DeviceInfo {
    private init() {}

    public static var current: DeviceInfo = DeviceInfo()

    public var name: String {
    #if canImport(WatchKit)
        WKInterfaceDevice.current().name
    #elseif canImport(UIKit)
        UIDevice.current.name
    #else
        ProcessInfo.processInfo.hostName
    #endif
    }

    public var hostName: String {
        ProcessInfo.processInfo.hostName
    }

    public var architecture: String {
    #if arch(x86_64)
        "x86_64"
    #elseif arch(arm64)
        "arm64"
    #else
        "unknown"
    #endif
    }

    public var model: String {
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

    public var operatingSystem: (name: String, version: String) {
    #if canImport(WatchKit)
        let device = WKInterfaceDevice.current()
        return (name: device.systemName, version: device.systemVersion)
    #elseif canImport(UIKit)
        let device = UIDevice.current
        return (name: device.systemName, version: device.systemVersion)
    #else
        return (name: "macOS",
                version: ProcessInfo.processInfo.operatingSystemVersionString)
    #endif
    }

    public var identifierForVendor: UUID? {
    #if canImport(WatchKit)
        WKInterfaceDevice.current().identifierForVendor
    #elseif canImport(UIKit)
        UIDevice.current.identifierForVendor
    #else
        nil
    #endif
    }

    public var screenBounds: CGRect {
    #if canImport(WatchKit)
        .zero
    #elseif canImport(UIKit)
        UIScreen.main.nativeBounds
    #elseif canImport(AppKit)
        NSScreen.main?.visibleFrame ?? .zero
    #endif
    }

#if canImport(IOKit)
    private func value(forKey key: String) -> String? {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }

        IOObjectRelease(service)
        return modelIdentifier
    }
#endif
}
