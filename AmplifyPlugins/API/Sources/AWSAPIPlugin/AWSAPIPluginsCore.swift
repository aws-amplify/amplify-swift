//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
import UIKit
#endif
import Foundation
import Amplify
import ClientRuntime
import AWSClientRuntime

// Things that came directly from AWSCore or depended on something from AWSCore
// TODO: Consolidate this to AWSPluginsCore for all other plugins to use.
struct AWSAPIPluginsCore {
    static let version = "1.16.1"

    static var platformMapping: [Platform: String] = [:]

    static var systemName: String {
#if canImport(UIKit)
        UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
#else
        "macOS"
#endif
    }
    static var systemVersion: String {
#if canImport(UIKit)
        UIDevice.current.systemVersion
#else
        ProcessInfo.processInfo.operatingSystemVersionString
#endif
    }

    static func baseUserAgent() -> String! {
        // TODO: Retrieve this version from a centralized location:
        //https://github.com/aws-amplify/amplify-ios/issues/276
        let platformInfo = AWSAPIPluginsCore.platformInformation()
        let systemName = Self.systemName
        let systemVersion = Self.systemVersion
        let localeIdentifier = Locale.current.identifier
        return "\(platformInfo) \(systemName)/\(systemVersion) \(localeIdentifier)"
    }

    public enum Platform: String {
        case flutter = "amplify-flutter"
    }

    static func platformInformation() -> String {
        var platformTokens = platformMapping.map { "\($0.rawValue)/\($1)" }
        platformTokens.append("amplify-iOS/\(AWSAPIPluginsCore.version)")
        return platformTokens.joined(separator: " ")
    }

    public static let AWSDateISO8601DateFormat2 = "yyyyMMdd'T'HHmmss'Z'"
}
