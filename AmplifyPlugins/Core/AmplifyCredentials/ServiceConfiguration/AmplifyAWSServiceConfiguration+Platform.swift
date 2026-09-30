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

    /// Snapshots the storage in a single locked read.
    ///
    /// Reading `keys` and then calling `getValue(forKey:)` per key took the lock once per entry, so a
    /// concurrent `addUserAgentPlatform` could land mid-loop and yield a snapshot that is missing the
    /// newest entry — or, if a key were ever removed, one that drops it. Iterating instead goes through
    /// `makeIterator()`, which takes the lock once and copies the whole dictionary, so the result is
    /// always a consistent point-in-time view.
    internal static var platformMapping: [Platform: String] {
        platformMappingStorage.reduce(into: [Platform: String]()) { result, entry in
            result[entry.key] = entry.value
        }
    }

    static func addUserAgentPlatform(_ platform: Platform, version: String) {
        platformMappingStorage.set(value: version, forKey: platform)
    }

    enum Platform: String, Sendable {
        case flutter = "amplify-flutter"
    }
}
