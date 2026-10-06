//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// Raw `SecItem` helpers for seeding and inspecting the real keychain around the scoped-wipe tests.
///
/// Items are written with `KeychainItemAttributes.addQuery`, the exact query `KeychainItemStore` adds
/// with, so a seeded item is indistinguishable from one the plugin wrote. Inspection lists
/// attributes and data together, which the iOS keychain allows.
enum RealKeychain {

    /// One stored item, as the keychain reports it.
    struct Row: Hashable, CustomStringConvertible {
        let account: String
        let group: String
        let value: String

        var description: String { "\(account)@\(group.split(separator: ".").last ?? "?")=\(value)" }
    }

    /// Adds `value` under `account` exactly as `KeychainItemStore` does, into `group` or, if `nil`, the
    /// app's default group.
    static func add(_ value: String, account: String, service: String, group: String? = nil) -> OSStatus {
        let query = KeychainItemAttributes(service: service, accessGroup: group)
            .addQuery(account: account, value: Data(value.utf8))
        return SecItemAdd(query as CFDictionary, nil)
    }

    /// Every item under `service`, in every visible access group (or only `group`), sorted.
    static func rows(service: String, group: String? = nil) -> [Row] {
        var query = KeychainItemAttributes(service: service, accessGroup: group).defaultGetQuery()
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            XCTAssertEqual(status, errSecItemNotFound, "listing \(service) failed: \(describe(status))")
            return []
        }
        return items.map { item in
            Row(
                account: item[kSecAttrAccount as String] as? String ?? "?",
                group: item[kSecAttrAccessGroup as String] as? String ?? "?",
                value: (item[kSecValueData as String] as? Data).map { String(decoding: $0, as: UTF8.self) } ?? "?"
            )
        }
        .sorted { ($0.account, $0.group) < ($1.account, $1.group) }
    }

    /// Deletes every item under `service` in every visible group. Repeated, so the cleanup does not
    /// depend on how far a single delete reaches.
    static func wipe(_ service: String) {
        let query = KeychainItemAttributes(service: service).defaultGetQuery()
        var status = errSecSuccess
        for _ in 0 ..< 5 where status == errSecSuccess {
            status = SecItemDelete(query as CFDictionary)
        }
        XCTAssertEqual(status, errSecItemNotFound, "could not wipe \(service): \(describe(status))")
        XCTAssertEqual(rows(service: service), [], "wipe left items in \(service)")
    }

    /// The group an item lands in when written with none: the first `keychain-access-groups` entry.
    static func defaultGroup() throws -> String {
        let service = "com.amplify.keychainWipeProbe.groupDiscovery.\(UUID().uuidString)"
        defer { wipe(service) }
        let status = add("", account: "discovery", service: service)
        XCTAssertEqual(status, errSecSuccess, "default-group discovery add: \(describe(status))")
        return try XCTUnwrap(rows(service: service).first?.group)
    }

    /// The second group in `AuthHostApp.entitlements`.
    static func sharedGroup(defaultGroup: String) -> String {
        XCTAssertTrue(defaultGroup.hasSuffix("com.aws.amplify.auth.AuthHostApp"), defaultGroup)
        return defaultGroup + "Shared"
    }

    static func describe(_ status: OSStatus) -> String {
        "\(status) (\(SecCopyErrorMessageString(status, nil) as String? ?? "no message"))"
    }

    /// Prints a finding so it can be read out of the `xcodebuild` log with `grep '\[RealKeychain\]'`.
    static func report(_ test: XCTestCase, _ line: String) {
        print("[RealKeychain] \(test.name): \(line)")
    }
}
