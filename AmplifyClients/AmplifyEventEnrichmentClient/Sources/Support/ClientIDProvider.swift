//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private let clientIDKey = "com.amplifyframework.device_id"

/// Resolves a persistent client/device identifier shared across Amplify packages.
///
/// Uses `UserDefaults.standard` with a read-or-create pattern under the key
/// `com.amplifyframework.device_id`. This key is shared with the Connect client
/// and matches the Flutter/Android implementations.
enum ClientIDProvider {
    /// Returns the persisted client identifier, creating and storing one if absent.
    ///
    /// The read-then-write is not atomic — `UserDefaults` offers no
    /// compare-and-set — so two clients constructed concurrently on a device's
    /// first launch may each mint an ID and one write wins. Subsequent calls all
    /// observe that winning value, so the identifier is stable from then on.
    static func resolve(userDefaults: UserDefaults = .standard) -> String {
        if let existing = userDefaults.string(forKey: clientIDKey), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: clientIDKey)
        return newId
    }
}
