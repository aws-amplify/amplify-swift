//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private let clientIDKey = "com.amazonaws.amplify.event_enrichment.client_id"

/// Resolves a persistent client/device identifier.
///
/// Uses `UserDefaults.standard` with a read-or-create pattern.
/// Whichever call initializes first generates the UUID; subsequent
/// calls read the existing value.
enum ClientIDProvider {
    static func resolve(userDefaults: UserDefaults = .standard) -> String {
        if let existing = userDefaults.string(forKey: clientIDKey), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: clientIDKey)
        return newId
    }
}
