//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Foundation
import Security
import XCTest

/// Pins the real keychain behaviour the shared keychain module's enumeration primitive
/// is designed against, using raw `SecItem` calls so it does not depend on that module landing.
///
/// Every query carries `kSecUseDataProtectionKeychain: true`, as `KeychainStoreAttributes` does.
/// Every item is written the way `KeychainStore._set` writes one — generic password,
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, no access group — under a service unique to
/// the test, which `tearDown` deletes.
///
/// Findings are printed with a `[KeychainProbe]` prefix so they can be read out of the
/// `xcodebuild` log.
final class DataProtectionKeychainProbeTests: XCTestCase {

    private var service = ""

    override func setUp() {
        super.setUp()
        service = "com.amplify.cognitoClient.integrationProbe.\(UUID().uuidString)"
    }

    override func tearDown() {
        // Repeated, so the cleanup does not itself depend on how far one delete reaches across
        // access groups — that reach is one of the things under test.
        var status = errSecSuccess
        for _ in 0 ..< 3 where status == errSecSuccess {
            status = SecItemDelete(baseQuery(service: service) as CFDictionary)
        }
        XCTAssertEqual(status, errSecItemNotFound, "tearDown could not delete the probe service: \(describe(status))")
        XCTAssertEqual(
            SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, nil),
            errSecItemNotFound,
            "tearDown left items behind in \(service)"
        )
        super.tearDown()
    }

    // MARK: - Tests

    /// The harness genuinely reaches the data-protection keychain.
    ///
    /// - Given: A test hosted in the iOS app, on a simulator
    /// - When:
    ///    - One item is added and read back with `kSecUseDataProtectionKeychain: true`
    /// - Then:
    ///    - Both succeed — in particular, neither returns `errSecMissingEntitlement`, which is
    ///      what the same calls return under an unsigned `swift test` on macOS
    ///
    func testReachesDataProtectionKeychain() throws {
        let payload = Data("probe".utf8)

        let addStatus = add(account: "amplify.probe.reachability", data: payload)
        XCTAssertNotEqual(addStatus, errSecMissingEntitlement, "The host app is not entitled to the keychain")
        XCTAssertEqual(addStatus, errSecSuccess, describe(addStatus))

        var query = baseQuery(service: service)
        query[kSecAttrAccount as String] = "amplify.probe.reachability"
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let readStatus = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertEqual(readStatus, errSecSuccess, describe(readStatus))
        XCTAssertEqual(result as? Data, payload)
    }

    /// An attributes-only enumeration returns every account name in the service.
    ///
    /// - Given: One service holding v1 session records for two session IDs (under both a
    ///   user-pool-only and a user-pool-plus-identity-pool namespace), a v1 challenge record, the
    ///   plugin's legacy session record, device-metadata and ASF records, and its stored
    ///   configuration — the full sibling set the enumeration will meet in the plugin's service
    /// - When:
    ///    - `SecItemCopyMatching` runs with `kSecReturnAttributes: true`,
    ///      `kSecMatchLimit: kSecMatchLimitAll`, no `kSecReturnData`, and no `kSecAttrAccount`
    /// - Then:
    ///    - It returns `errSecSuccess` and an array of attribute dictionaries
    ///    - Every dictionary carries `kSecAttrAccount` as a `String`, and no `kSecValueData`
    ///    - The account names are exactly the ones written, byte for byte (`$`, `:` included)
    ///    - `SessionRecordKey.parse` over the result picks out exactly the v1 records
    ///
    func testAttributesOnlyEnumerationReturnsEveryAccount() throws {
        let names = ProbeAccounts.make()
        for account in names.all {
            let status = add(account: account, data: Data("secret-\(account)".utf8))
            XCTAssertEqual(status, errSecSuccess, "add \(account): \(describe(status))")
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess, describe(status))

        report("enumeration status: \(describe(status))")
        report("result CF type: \(result.map { String(describing: CFCopyTypeIDDescription(CFGetTypeID($0))) } ?? "nil")")
        report("result Swift cast [[String: Any]]: \(result is [[String: Any]])")

        let rows = try XCTUnwrap(result as? [[String: Any]], "Expected an array of attribute dictionaries")
        report("row count: \(rows.count) (written: \(names.all.count))")
        let keySets = Set(rows.map { $0.keys.sorted().joined(separator: ",") })
        report("distinct attribute key sets across rows: \(keySets.count)")
        for keySet in keySets {
            report("attribute keys: \(keySet)")
        }
        if let first = rows.first {
            for key in first.keys.sorted() {
                report("  \(key) = \(renderAttribute(first[key]))")
            }
        }

        var returned: [String] = []
        for row in rows {
            XCTAssertNil(row[kSecValueData as String], "Attributes-only enumeration returned item data")
            let account = try XCTUnwrap(row[kSecAttrAccount as String] as? String, "Row without a String account: \(row.keys)")
            returned.append(account)
            XCTAssertEqual(row[kSecAttrService as String] as? String, service)
        }
        report("returned order == insertion order: \(returned == names.all)")
        report("returned accounts: \(returned)")

        XCTAssertEqual(returned.count, names.all.count, "Duplicate or missing rows")
        XCTAssertEqual(Set(returned), Set(names.all))

        let parsed = returned.compactMap(SessionRecordKey.parse)
        XCTAssertEqual(
            Set(parsed.map { "\($0.namespaceComponent)|\($0.sessionId.stringValue)|\($0.kind.rawValue)" }),
            names.expectedV1Parses
        )
    }

    /// A single match still comes back as an array.
    ///
    /// - Given: A service holding exactly one item
    /// - When:
    ///    - The attributes-only `kSecMatchLimitAll` enumeration runs
    /// - Then:
    ///    - The result is a one-element array, not a bare dictionary, so callers need one code path
    ///
    func testEnumerationOfOneItemReturnsOneElementArray() throws {
        let account = "amplify.1.us-west-2_probe.$default.session"
        XCTAssertEqual(add(account: account, data: Data("x".utf8)), errSecSuccess)

        var result: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, &result), errSecSuccess)

        XCTAssertNil(result as? [String: Any], "A single match came back as a bare dictionary")
        let rows = try XCTUnwrap(result as? [[String: Any]])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?[kSecAttrAccount as String] as? String, account)
    }

    /// An empty service is `errSecItemNotFound`, not an empty array.
    ///
    /// - Given: A service no item has ever been written to
    /// - When:
    ///    - The attributes-only `kSecMatchLimitAll` enumeration runs
    /// - Then:
    ///    - It returns `errSecItemNotFound` and leaves the result `nil` — so the primitive must map
    ///      that status to `[]` itself, and treat every other non-success status as a failure
    ///
    func testEnumerationOfEmptyServiceReturnsItemNotFound() {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, &result)
        report("empty-service status: \(describe(status)); result nil: \(result == nil)")
        XCTAssertEqual(status, errSecItemNotFound, describe(status))
        XCTAssertNil(result)
    }

    /// Enumeration is scoped to its service.
    ///
    /// - Given: Items in the probe service and in a sibling service (as the plugin's
    ///   `com.amplify.awsCognitoAuthPlugin` and `…Shared` services are siblings)
    /// - When:
    ///    - The probe service is enumerated
    /// - Then:
    ///    - Only its own accounts come back
    ///
    func testEnumerationIsScopedToService() throws {
        let sibling = service + ".sibling"
        defer { SecItemDelete(baseQuery(service: sibling) as CFDictionary) }

        XCTAssertEqual(add(account: "amplify.1.us-west-2_probe.mine.session", data: Data("a".utf8)), errSecSuccess)
        XCTAssertEqual(
            add(account: "amplify.1.us-west-2_probe.theirs.session", data: Data("b".utf8), service: sibling),
            errSecSuccess
        )

        var result: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, &result), errSecSuccess)
        let accounts = try XCTUnwrap(result as? [[String: Any]]).compactMap { $0[kSecAttrAccount as String] as? String }
        XCTAssertEqual(accounts, ["amplify.1.us-west-2_probe.mine.session"])
    }

    /// Records what happens if an enumeration also asks for data.
    ///
    /// - Given: A service holding three items
    /// - When:
    ///    - `kSecReturnAttributes` and `kSecReturnData` are both set with `kSecMatchLimitAll`
    /// - Then:
    ///    - The observed status and shape are printed and pinned, so the keychain track knows
    ///      whether "attributes only" is a requirement of the platform or only of the design
    ///
    func testEnumerationWithDataBehaviour() throws {
        for account in ["amplify.1.p.a.session", "amplify.1.p.b.session", "amplify.p.session"] {
            XCTAssertEqual(add(account: account, data: Data(account.utf8)), errSecSuccess)
        }

        var query = enumerationQuery(service: service)
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        report("attributes+data+MatchLimitAll status: \(describe(status))")
        let rows = result as? [[String: Any]]
        report("attributes+data rows: \(rows?.count ?? -1); every row has data: \(rows?.allSatisfy { $0[kSecValueData as String] is Data } ?? false)")

        // iOS permits returning data for every match; macOS's legacy file keychain does not.
        XCTAssertEqual(status, errSecSuccess, describe(status))
        XCTAssertEqual(rows?.count, 3)
    }

    /// A delete keyed only on class and service removes every item in the service.
    ///
    /// - Given: A service holding the full sibling set, v1 records included
    /// - When:
    ///    - `SecItemDelete` runs with class + service + `kSecUseDataProtectionKeychain`, no account
    ///      and no match limit — the query `KeychainStore._removeAll()` issues on iOS
    /// - Then:
    ///    - Every item is gone, v1 records included. This is the wipe the scoped wipe must narrow
    ///
    func testServiceWideDeleteRemovesEveryItem() {
        let names = ProbeAccounts.make()
        for account in names.all {
            XCTAssertEqual(add(account: account, data: Data("x".utf8)), errSecSuccess)
        }

        let status = SecItemDelete(baseQuery(service: service) as CFDictionary)
        report("service-wide delete status: \(describe(status))")
        XCTAssertEqual(status, errSecSuccess, describe(status))
        XCTAssertEqual(SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, nil), errSecItemNotFound)
    }

    // MARK: - Access groups (duplicates in an unscoped listing)

    /// Items written without an access group all land in the default group, once each.
    ///
    /// - Given: The full sibling set written with no `kSecAttrAccessGroup`, by an app entitled to
    ///   two keychain access groups
    /// - When:
    ///    - The service is listed with no `kSecAttrAccessGroup` in the query
    /// - Then:
    ///    - Every row is in the app's default (first) access group
    ///    - No account appears twice
    ///
    func testUnscopedListingOfDefaultGroupHasNoDuplicates() throws {
        let defaultGroup = try defaultAccessGroup()
        report("default access group: \(defaultGroup)")
        let names = ProbeAccounts.make()
        for account in names.all {
            XCTAssertEqual(add(account: account, data: Data("x".utf8)), errSecSuccess)
        }

        let rows = try list()
        let accounts = rows.compactMap { $0[kSecAttrAccount as String] as? String }
        let groups = Set(rows.compactMap { $0[kSecAttrAccessGroup as String] as? String })
        report("default-group listing: \(rows.count) rows, \(Set(accounts).count) distinct accounts, groups \(groups)")

        XCTAssertEqual(groups, [defaultGroup])
        XCTAssertEqual(accounts.count, Set(accounts).count, "Duplicate accounts in a single-group listing")
        XCTAssertEqual(Set(accounts), Set(names.all))
    }

    /// The same account in two access groups is two items, and an unscoped listing returns both.
    ///
    /// - Given: One account written twice under one service — once with no access group (so, the
    ///   default group) and once into the app's second entitled group
    /// - When:
    ///    - The service is listed with no `kSecAttrAccessGroup` in the query
    /// - Then:
    ///    - Both writes succeed: the access group is part of the item's identity
    ///    - The listing returns **two rows with the same `kSecAttrAccount`**, told apart only by
    ///      `kSecAttrAccessGroup` — so an unscoped listing must be de-duplicated, or scoped
    ///
    func testUnscopedListingReturnsOneRowPerAccessGroup() throws {
        let defaultGroup = try defaultAccessGroup()
        let sharedGroup = try sharedAccessGroup(defaultGroup: defaultGroup)
        let account = "amplify.1.us-west-2_probe.$default.session"

        XCTAssertEqual(add(account: account, data: Data("default-group".utf8)), errSecSuccess)
        let sharedStatus = add(account: account, data: Data("shared-group".utf8), accessGroup: sharedGroup)
        report("add same account into \(sharedGroup): \(describe(sharedStatus))")
        XCTAssertEqual(sharedStatus, errSecSuccess, describe(sharedStatus))

        let rows = try list()
        let pairs = rows.map {
            "\($0[kSecAttrAccount as String] as? String ?? "?")@\($0[kSecAttrAccessGroup as String] as? String ?? "?")"
        }
        report("two-group unscoped listing: \(rows.count) rows: \(pairs.sorted())")

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(Set(rows.compactMap { $0[kSecAttrAccount as String] as? String }), [account])
        XCTAssertEqual(Set(rows.compactMap { $0[kSecAttrAccessGroup as String] as? String }), [defaultGroup, sharedGroup])

        // Scoping the listing to one group returns only that group's row.
        var scoped = enumerationQuery(service: service)
        scoped[kSecAttrAccessGroup as String] = sharedGroup
        var result: CFTypeRef?
        XCTAssertEqual(SecItemCopyMatching(scoped as CFDictionary, &result), errSecSuccess)
        XCTAssertEqual((result as? [[String: Any]])?.count, 1)

        // An unscoped single-item read returns one of the two; record which.
        let (status, data) = readData(account: account)
        report("unscoped MatchLimitOne read with two groups: \(describe(status)); got \(data.map { String(decoding: $0, as: UTF8.self) } ?? "nil")")
        XCTAssertEqual(status, errSecSuccess)
    }

    /// An unscoped update or delete reaches the account in every access group.
    ///
    /// - Given: One account in both the default and the shared access group
    /// - When:
    ///    - `SecItemUpdate` runs with no `kSecAttrAccessGroup` in the query, then `SecItemDelete` the same
    /// - Then:
    ///    - The observed reach is printed and pinned: whether one or both copies changed, and
    ///      whether one or both were deleted
    ///
    func testUnscopedUpdateAndDeleteReachEveryAccessGroup() throws {
        let defaultGroup = try defaultAccessGroup()
        let sharedGroup = try sharedAccessGroup(defaultGroup: defaultGroup)
        let account = "amplify.1.us-west-2_probe.work.session"
        XCTAssertEqual(add(account: account, data: Data("old".utf8)), errSecSuccess)
        XCTAssertEqual(add(account: account, data: Data("old".utf8), accessGroup: sharedGroup), errSecSuccess)

        let updateStatus = SecItemUpdate(
            itemQuery(account: account) as CFDictionary,
            [kSecValueData as String: Data("new".utf8)] as CFDictionary
        )
        let inDefault = readData(account: account, accessGroup: defaultGroup).1.map { String(decoding: $0, as: UTF8.self) }
        let inShared = readData(account: account, accessGroup: sharedGroup).1.map { String(decoding: $0, as: UTF8.self) }
        report("unscoped update across two groups: \(describe(updateStatus)); default=\(inDefault ?? "nil") shared=\(inShared ?? "nil")")
        XCTAssertEqual(updateStatus, errSecSuccess)
        XCTAssertEqual(inDefault, "new")
        XCTAssertEqual(inShared, "new", "An unscoped update changed only one group's copy")

        let deleteStatus = SecItemDelete(itemQuery(account: account) as CFDictionary)
        let remaining = try list().count
        report("unscoped delete across two groups: \(describe(deleteStatus)); rows remaining \(remaining)")
        XCTAssertEqual(deleteStatus, errSecSuccess)
        XCTAssertEqual(remaining, 0, "An unscoped delete removed only one group's copy")
    }

    // MARK: - Writes (plain update, conditional-write statuses)

    /// A plain `SecItemUpdate` replaces an existing item's data in place.
    ///
    /// - Given: An item written as `KeychainStore._set` writes one
    /// - When:
    ///    - `SecItemUpdate` runs with the class/service/account query (plus
    ///      `kSecUseDataProtectionKeychain`) and `[kSecValueData: new]` — no delete-then-add
    /// - Then:
    ///    - It returns `errSecSuccess`, a read returns the new data, the listing still has one row,
    ///      and the item's accessibility class is unchanged
    ///
    func testPlainUpdateReplacesData() throws {
        let account = "amplify.1.us-west-2_probe.$default.session"
        XCTAssertEqual(add(account: account, data: Data("before".utf8)), errSecSuccess)
        let before = try readAttributes(account: account)

        let status = SecItemUpdate(
            itemQuery(account: account) as CFDictionary,
            [kSecValueData as String: Data("after".utf8)] as CFDictionary
        )
        report("plain SecItemUpdate status: \(describe(status))")
        XCTAssertEqual(status, errSecSuccess, describe(status))

        let (readStatus, data) = readData(account: account)
        XCTAssertEqual(readStatus, errSecSuccess)
        XCTAssertEqual(data, Data("after".utf8))
        XCTAssertEqual(try list().count, 1)

        let after = try readAttributes(account: account)
        let accessibleBefore = before[kSecAttrAccessible as String] as? String
        let accessibleAfter = after[kSecAttrAccessible as String] as? String
        report("accessible before/after update: \(accessibleBefore ?? "nil")/\(accessibleAfter ?? "nil"); "
            + "mdat advanced: \(((after[kSecAttrModificationDate as String] as? Date) ?? .distantPast) >= ((before[kSecAttrModificationDate as String] as? Date) ?? .distantFuture))")
        XCTAssertEqual(accessibleAfter, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        XCTAssertEqual(accessibleAfter, accessibleBefore)
    }

    /// Adding an account that already exists is `errSecDuplicateItem`, and changes nothing.
    ///
    /// - Given: An existing item
    /// - When:
    ///    - `SecItemAdd` runs again for the same service and account with different data
    /// - Then:
    ///    - It returns `errSecDuplicateItem` (-25299) and the stored data is the original
    ///
    func testAddOfExistingAccountReturnsDuplicateItem() {
        let account = "amplify.1.us-west-2_probe.work.session"
        XCTAssertEqual(add(account: account, data: Data("first".utf8)), errSecSuccess)

        let status = add(account: account, data: Data("second".utf8))
        report("SecItemAdd on existing account: \(describe(status))")
        XCTAssertEqual(status, errSecDuplicateItem, describe(status))
        XCTAssertEqual(status, -25_299)
        XCTAssertEqual(readData(account: account).1, Data("first".utf8))
    }

    /// Updating an account that does not exist is `errSecItemNotFound`, and creates nothing.
    ///
    /// - Given: An empty service
    /// - When:
    ///    - `SecItemUpdate` runs for an account that was never written
    /// - Then:
    ///    - It returns `errSecItemNotFound` (-25300), and the service is still empty
    ///
    func testUpdateOfMissingAccountReturnsItemNotFound() throws {
        let status = SecItemUpdate(
            itemQuery(account: "amplify.1.us-west-2_probe.missing.session") as CFDictionary,
            [kSecValueData as String: Data("x".utf8)] as CFDictionary
        )
        report("SecItemUpdate on missing account: \(describe(status))")
        XCTAssertEqual(status, errSecItemNotFound, describe(status))
        XCTAssertEqual(status, -25_300)
        XCTAssertEqual(try list().count, 0)
    }

    // MARK: - Queries

    private func baseQuery(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    /// The enumeration the keychain track specifies: attributes only, every match.
    private func enumerationQuery(service: String) -> [String: Any] {
        var query = baseQuery(service: service)
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        return query
    }

    private func add(account: String, data: Data, service: String? = nil, accessGroup: String? = nil) -> OSStatus {
        var attributes = baseQuery(service: service ?? self.service)
        attributes[kSecAttrAccount as String] = account
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecValueData as String] = data
        if let accessGroup {
            attributes[kSecAttrAccessGroup as String] = accessGroup
        }
        return SecItemAdd(attributes as CFDictionary, nil)
    }

    /// The query `KeychainStore` uses to address one item: no access group, no match limit.
    private func itemQuery(account: String, accessGroup: String? = nil) -> [String: Any] {
        var query = baseQuery(service: service)
        query[kSecAttrAccount as String] = account
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    private func readData(account: String, accessGroup: String? = nil) -> (OSStatus, Data?) {
        var query = itemQuery(account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result as? Data)
    }

    private func readAttributes(account: String) throws -> [String: Any] {
        var query = itemQuery(account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess, describe(status))
        return try XCTUnwrap(result as? [String: Any])
    }

    private func list() throws -> [[String: Any]] {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(enumerationQuery(service: service) as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        XCTAssertEqual(status, errSecSuccess, describe(status))
        return try XCTUnwrap(result as? [[String: Any]])
    }

    private func defaultAccessGroup() throws -> String {
        try IntegrationTestEnvironment.defaultAccessGroup()
    }

    private func sharedAccessGroup(defaultGroup: String) throws -> String {
        let shared = try IntegrationTestEnvironment.sharedAccessGroup()
        XCTAssertEqual(shared, defaultGroup + "Shared")
        return shared
    }

    // MARK: - Reporting

    private func describe(_ status: OSStatus) -> String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "no message"
        return "\(status) (\(message))"
    }

    private func renderAttribute(_ value: Any?) -> String {
        switch value {
        case nil:
            return "nil"
        case let data as Data:
            return "Data(\(data.count) bytes)"
        case let date as Date:
            return "Date(\(date))"
        case let number as NSNumber:
            return "\(type(of: number))(\(number))"
        case let string as String:
            return "\"\(string)\""
        case let value?:
            return "\(type(of: value))(\(value))"
        }
    }

    /// Redacted first: an enumeration can list other suites' session records, whose accounts embed the
    /// sandbox pool ids.
    private func report(_ line: String) {
        print("[KeychainProbe] \(name): \(RealKeychain.redact(line))")
    }
}

/// The account names a real plugin service holds, plus the client's v1 records beside them.
private struct ProbeAccounts {
    let all: [String]
    /// `namespace|sessionId|kind` for each account that is a v1 record.
    let expectedV1Parses: Set<String>

    static func make() -> ProbeAccounts {
        let configuration = try? IntegrationTestEnvironment.configuration()
        let userPoolId = configuration?.userPool?.poolId ?? "us-west-2_PROBE0000"
        let identityPoolId = configuration?.identityPool?.poolId ?? "us-west-2:00000000-0000-0000-0000-000000000000"
        let work = SessionID.namedForProbe("work")

        let userPoolOnly = PoolNamespace.userPool(userPoolId)
        let bothPools = PoolNamespace.userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId)

        let v1: [(PoolNamespace, SessionID, SessionRecordKey.Kind)] = [
            (userPoolOnly, work, .session),
            (userPoolOnly, .default, .session),
            (bothPools, work, .session),
            (bothPools, .default, .session),
            (bothPools, work, .challenge)
        ]
        let v1Accounts = v1.map { SessionRecordKey.account(for: $0.1, in: $0.0, kind: $0.2) }

        // Literal, so the probe also pins the shapes the task specifies independently of the
        // key builder: `amplify.1.<userPoolId>.work.session` and `…$default.session`.
        precondition(v1Accounts[0] == "amplify.1.\(userPoolId).work.session")
        precondition(v1Accounts[1] == "amplify.1.\(userPoolId).$default.session")

        // The plugin's own records, as `AWSCognitoAuthCredentialStore` names them.
        let pluginAccounts = [
            "amplify.\(userPoolId).session",
            "amplify.\(userPoolId).\(identityPoolId).session",
            "amplify.\(userPoolId).\(identityPoolId).alice.deviceMetadata",
            "amplify.\(userPoolId).\(identityPoolId).Alice.deviceASF",
            "authConfiguration"
        ]

        return ProbeAccounts(
            all: v1Accounts + pluginAccounts,
            expectedV1Parses: Set(v1.map { "\($0.0.keyComponent)|\($0.1.stringValue)|\($0.2.rawValue)" })
        )
    }
}

private extension SessionID {
    static func namedForProbe(_ id: String) -> SessionID {
        // swiftlint:disable:next force_try
        try! SessionID.named(id)
    }
}
