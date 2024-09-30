//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

struct OSMetadata {
    let family: PlatformOperatingSystem
    let version: String?
    let additionalMetadata: [AdditionalMetadata]
    #if targetEnvironment(simulator)
    let simulatorMetadata = [AdditionalMetadata(name: "simulator")]
    #endif

    init(family: PlatformOperatingSystem, version: String? = nil, additionalMetadata: [AdditionalMetadata] = []) {
        self.family = family
        self.version = version
        #if targetEnvironment(simulator)
        self.additionalMetadata = additionalMetadata + simulatorMetadata
        #else
        self.additionalMetadata = additionalMetadata
        #endif
    }
}

extension OSMetadata: CustomStringConvertible {

    var description: String {
        var description = "os/\(family.userAgentName)"
        if let version = version, !version.isEmpty {
            description += "#\(version.userAgentToken)"
        }
        return ([description] + additionalMetadata.map(\.description)).joined(separator: " ")
    }
}

private extension PlatformOperatingSystem {

    var userAgentName: String {
        switch self {
        case .windows: return "windows"
        case .linux: return "linux"
        case .iOS: return "ios"
        case .macOS: return "macos"
        case .watchOS: return "watchos"
        case .tvOS: return "tvos"
        case .visionOS: return "visionos"
        case .unknown: return "other"
        }
    }
}
