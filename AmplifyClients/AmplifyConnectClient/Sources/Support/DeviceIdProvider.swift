//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private let deviceIdKey = "com.amplifyframework.device_id"

/// Resolves a persistent device identifier shared across Amplify packages.
///
/// Uses `UserDefaults.standard` with a read-or-create pattern.
/// The key `com.amplifyframework.device_id` is shared with the event
/// enrichment client and matches the Flutter/Android implementations.
enum DeviceIdProvider {
    static func resolve(userDefaults: UserDefaults = .standard) -> String {
        if let existing = userDefaults.string(forKey: deviceIdKey), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: deviceIdKey)
        return newId
    }
}
