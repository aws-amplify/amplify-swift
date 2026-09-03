//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AmplifyAWSServiceConfiguration {

    /// Backed by `AtomicDictionary` rather than a plain `static var`: `addUserAgentPlatform` is
    /// public API called by wrapper SDKs such as Amplify Flutter, so writes can arrive from any
    /// thread and an unsynchronized global is an error in the Swift 6 language mode.
    private static let platformMappingStorage = AtomicDictionary<Platform, String>()

    internal static var platformMapping: [Platform: String] {
        platformMappingStorage.keys.reduce(into: [Platform: String]()) { result, key in
            if let version = platformMappingStorage.getValue(forKey: key) {
                result[key] = version
            }
        }
    }

    static func addUserAgentPlatform(_ platform: Platform, version: String) {
        platformMappingStorage.set(value: version, forKey: platform)
    }

    enum Platform: String, Sendable {
        case flutter = "amplify-flutter"
    }
}
