//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(IOKit)
import IOKit
#endif

public struct PlatformInfo {
    var name: String {
#if canImport(UIKit)
        UIDevice.current.name
#else
        ProcessInfo.processInfo.hostName
#endif
    }

    var hostName: String {
        ProcessInfo.processInfo.hostName
    }

    var architecture: String {
#if arch(x86_64)
        "x86_64"
#elseif arch(arm64)
        "arm64"
#else
        "unknown"
#endif
    }

    var model: String {
#if canImport(UIKit)
        UIDevice.current.model
#elseif canImport(IOKit)
        getValue(key: "model") ?? "Mac"
#endif
    }

#if canImport(IOKit)
    private func getValue(key: String) -> String? {
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
