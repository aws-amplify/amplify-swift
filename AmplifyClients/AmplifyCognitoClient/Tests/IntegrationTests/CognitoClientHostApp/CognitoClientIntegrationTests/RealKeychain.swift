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

/// Raw `SecItem` helpers for seeding and inspecting the real keychain around the keychain-module ports
/// (`KeychainModuleRealKeychainTests`).
///
/// Items are written with `KeychainItemAttributes.addQuery`, the exact query `KeychainItemStore` adds
/// with, so a seeded item is indistinguishable from one the plugin or the client wrote. Inspection lists
/// attributes and data together, which the iOS keychain allows.
enum RealKeychain {

    /// One stored item, as the keychain reports it.
    struct Row: Hashable, CustomStringConvertible {
        let account: String
        let group: String
        let value: String

        /// Account and group only, never `value`: a real session record holds tokens. The account's sandbox
        /// identifiers are redacted (`redact(_:)`), so a sandbox pool id never reaches the log.
        var description: String { "\(RealKeychain.redact(account))@\(group.split(separator: ".").last ?? "?")" }
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
        XCTAssertEqual(rows(service: service).map(\.description), [], "wipe left items in \(service)")
    }

    /// The group an item lands in when written with none: the first `keychain-access-groups` entry.
    static func defaultGroup() throws -> String {
        let service = "com.amplify.keychainWipeProbe.groupDiscovery.\(UUID().uuidString)"
        defer { wipe(service) }
        let status = add("", account: "discovery", service: service)
        XCTAssertEqual(status, errSecSuccess, "default-group discovery add: \(describe(status))")
        return try XCTUnwrap(rows(service: service).first?.group)
    }

    /// The second group in `CognitoClientHostApp.entitlements`.
    static func sharedGroup(defaultGroup: String) -> String {
        XCTAssertTrue(defaultGroup.hasSuffix("com.aws.amplify.cognitoclient.CognitoClientHostApp"), defaultGroup)
        return defaultGroup + "Shared"
    }

    static func describe(_ status: OSStatus) -> String {
        "\(status) (\(SecCopyErrorMessageString(status, nil) as String? ?? "no message"))"
    }

    /// Prints a finding so it can be read out of the `xcodebuild` log with `grep '\[RealKeychain\]'`.
    /// The line is redacted (`redact(_:)`) first.
    static func report(_ test: XCTestCase, _ line: String) {
        print("[RealKeychain] \(test.name): \(redact(line))")
    }

    /// `text` with every sandbox identifier the bundled `*amplify_outputs.json` files carry (user pool,
    /// identity pool and app client ids) replaced by `<userPool>`, `<identityPool>` and `<appClient>`, and
    /// any other identity-pool-shaped id (`<region>:<uuid>`) by `<identityPool>`. The tests' synthetic
    /// namespaces (`us-east-1_KcWipeOld`) are kept, so their findings stay readable. The interop target's
    /// `RealKeychain.redact(_:)` does the same over its own bundle.
    static func redact(_ text: String) -> String {
        var redacted = text
        for (identifier, placeholder) in sandboxIdentifiers {
            redacted = redacted.replacingOccurrences(of: identifier, with: placeholder)
        }
        return redacted.replacingOccurrences(
            of: #"[a-z]{2}(-[a-z]+)+-[0-9]:[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}"#,
            with: "<identityPool>",
            options: .regularExpression
        )
    }

    /// The identifiers in every role's outputs the "Copy test configuration" phase put in the bundle (a Gen1
    /// file through its Gen2 translation), longest first, so an id that contains another is replaced whole.
    private static let sandboxIdentifiers: [(String, String)] = {
        let fields = [
            ("user_pool_id", "<userPool>"),
            ("identity_pool_id", "<identityPool>"),
            ("user_pool_client_id", "<appClient>")
        ]
        var identifiers: [(String, String)] = []
        for pool in SandboxPool.everyRole where IntegrationTestEnvironment.hasOutputs(pool) {
            guard let auth = try? IntegrationTestEnvironment.outputsAuthSection(pool) else {
                continue
            }
            for (field, placeholder) in fields {
                if let identifier = auth[field] as? String, !identifier.isEmpty {
                    identifiers.append((identifier, placeholder))
                }
            }
        }
        return identifiers.sorted { $0.0.count > $1.0.count }
    }()
}
