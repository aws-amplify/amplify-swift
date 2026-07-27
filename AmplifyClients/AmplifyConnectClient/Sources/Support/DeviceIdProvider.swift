//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The shared, deliberately un-namespaced storage key for the device identifier.
///
/// This exact string is also used by the Flutter and Android implementations and by
/// ``AmplifyEventEnrichmentClient``, so it is intentionally **not** scoped by app ID,
/// region, or client instance — see ``DeviceIdProvider`` for the reasoning.
private let deviceIdKey = "com.amplifyframework.device_id"

/// Resolves a persistent device identifier shared across Amplify packages.
///
/// Uses `UserDefaults.standard` with a read-or-create pattern: the first caller
/// generates a UUID and persists it; every later caller reads that same value.
///
/// ## Scope: one identifier per app installation
///
/// The identifier is scoped to the app installation, not to a client instance,
/// a region, or a Connect endpoint. This is deliberate:
///
/// - **Cross-platform parity.** The key `com.amplifyframework.device_id` is the same
///   string used by the Flutter and Android Connect clients, so a device resolves to
///   one identifier regardless of which Amplify library registers it.
/// - **Cross-package consistency.** `AmplifyEventEnrichmentClient` reads the same key,
///   so analytics events and push registrations attribute to the same device.
/// - **Stable device registration.** `registerDevice(token:)` and `removeDevice()` must
///   agree on the identifier across app launches, or every launch would create a new
///   device object on the profile and `removeDevice()` could not find one to delete.
///
/// ### Multiple clients in one app
///
/// Creating several ``AmplifyConnectClient`` instances — including ones pointed at
/// different regions or endpoints — is supported, and all of them resolve to the
/// *same* device identifier. The identifier answers "which device is this?", not
/// "which backend is this?", so it does not vary per client. Consequences:
///
/// - Registering the same device against two backends produces one device object per
///   backend, each keyed by the same identifier. This is the intended behavior; the
///   backends are independent and the identifier stays comparable across them.
/// - `removeDevice()` removes the registration from whichever endpoint that client is
///   configured for; it does not affect registrations made through another client.
///
/// Namespacing the key per client or per endpoint would break both cross-platform and
/// cross-package parity, and would let one app accumulate several identifiers for a
/// single physical device.
enum DeviceIdProvider {
    /// Returns the persisted device identifier, creating and storing one if absent.
    ///
    /// - Parameter userDefaults: The store to read from and write to. Defaults to
    ///   `.standard`; injectable for testing.
    static func resolve(userDefaults: UserDefaults = .standard) -> String {
        if let existing = userDefaults.string(forKey: deviceIdKey), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: deviceIdKey)
        return newId
    }
}
