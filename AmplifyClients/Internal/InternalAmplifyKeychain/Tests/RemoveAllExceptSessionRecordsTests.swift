//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyKeychainTestCommon
import Foundation
import Security
import XCTest
@testable import InternalAmplifyKeychain

/// The scoped replacement for a service-wide `removeAll()`: it removes everything except the standalone
/// clients' session records, and removes nothing at all if it cannot list what is there.
final class RemoveAllExceptSessionRecordsTests: XCTestCase {

    private let service = "com.amplify.awsCognitoAuthPlugin"

    /// Every account `AWSCognitoAuthPlugin` writes under its service, plus one this test does not
    /// recognise, which a service-wide clear has always removed too.
    private let pluginAccounts = [
        "authConfiguration",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.session",
        "amplify.us-east-1_Pool.session",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.alice@example.com.deviceMetadata",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.Alice@Example.com.deviceASF",
        "some.unrecognised.item"
    ]

    /// Session records written by a standalone client, in each namespace shape and of each kind.
    private let sessionRecordAccounts = [
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.session",
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.challenge",
        "amplify.1.us-east-1_Pool.$default.session",
        "amplify.1.us-east-1:identity-pool.$default.challenge"
    ]

    /// Plugin items are removed and session records are kept.
    ///
    /// - Given: a service holding every kind of plugin item and client session records of both kinds
    /// - When: `removeAllExceptSessionRecords` runs over it
    /// - Then:
    ///    - every plugin item is gone
    ///    - every session record is still there with its bytes unchanged
    ///    - the service-wide `removeAll` was never used
    func testRemovesEveryPluginItemAndSparesSessionRecords() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try populate(store, with: pluginAccounts + sessionRecordAccounts)

        try store.removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        for account in pluginAccounts {
            XCTAssertNil(keychain.value(service: service, account: account), "\(account) should be removed")
        }
        for account in sessionRecordAccounts {
            XCTAssertEqual(keychain.value(service: service, account: account), Data(account.utf8), "\(account) should be kept")
        }
        XCTAssertFalse(keychain.mutations.contains(.removeAll(service: service)))
    }

    /// If the listing fails, nothing is removed: there is no fall-back to a service-wide clear.
    ///
    /// - Given: a service holding plugin items and session records, whose listing fails as a locked
    ///   device's does
    /// - When: `removeAllExceptSessionRecords` runs over it
    /// - Then:
    ///    - it throws the listing error
    ///    - every item, plugin-owned or not, is still there, and nothing was removed
    ///    - a warning was logged
    func testListingFailureRemovesNothing() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try populate(store, with: pluginAccounts + sessionRecordAccounts)
        keychain.resetMutations()
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)
        let logger = RecordingLogger()

        XCTAssertThrowsError(try store.removeAllExceptSessionRecords(logger: logger, sparingDefaultSessionItems: true)) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }

        for account in pluginAccounts + sessionRecordAccounts {
            XCTAssertNotNil(keychain.value(service: service, account: account), "\(account) should be kept")
        }
        XCTAssertEqual(keychain.mutations, [])
        XCTAssertEqual(logger.messages(at: .warn).count, 1)
    }

    /// With no session records present, the result is exactly that of `removeAll()`.
    ///
    /// - Given: two identical services holding only plugin items (including one this test does not
    ///   recognise), and no session records
    /// - When: one is cleared with `removeAll()` and the other with `removeAllExceptSessionRecords`
    /// - Then:
    ///    - both are left empty, so an app that never uses a standalone client sees no difference
    func testWithoutSessionRecordsTheResultEqualsRemoveAll() throws {
        let unscoped = InMemoryKeychain()
        let scoped = InMemoryKeychain()
        try populate(unscoped.store(service: service), with: pluginAccounts)
        try populate(scoped.store(service: service), with: pluginAccounts)

        try unscoped.store(service: service).removeAll()
        try scoped.store(service: service).removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        XCTAssertEqual(try unscoped.store(service: service).allAccounts(), [])
        XCTAssertEqual(try scoped.store(service: service).allAccounts(), [])
    }

    /// A store scoped to an access group touches only that group and its own service.
    ///
    /// Only a grouped store is exercised, because exact group matching is real behaviour only there. A
    /// store **without** an access group issues unscoped queries, and on a device those reach the account
    /// in every access group the app can see, exactly as `removeAll()` does.
    ///
    /// - Given: plugin items in the store's service under its access group, in the same service under
    ///   another access group, and in another service under the same group
    /// - When: `removeAllExceptSessionRecords` runs over the store scoped to `group-a`
    /// - Then:
    ///    - only that store's item is removed
    func testGroupedStoreTouchesOnlyItsOwnServiceAndAccessGroup() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain.store(service: service, accessGroup: "group-a"), with: ["authConfiguration"])
        try populate(keychain.store(service: service, accessGroup: "group-b"), with: ["authConfiguration"])
        try populate(keychain.store(service: "other", accessGroup: "group-a"), with: ["authConfiguration"])

        try keychain.store(service: service, accessGroup: "group-a").removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        XCTAssertNil(keychain.value(service: service, accessGroup: "group-a", account: "authConfiguration"))
        XCTAssertNotNil(keychain.value(service: service, accessGroup: "group-b", account: "authConfiguration"))
        XCTAssertNotNil(keychain.value(service: "other", accessGroup: "group-a", account: "authConfiguration"))
    }

    /// An account stored in two access groups is removed from both, even if each delete takes only one
    /// copy.
    ///
    /// The listing returns one row per copy, and each row gets its own removal. So a delete that
    /// honours a match limit of one, as some macOS paths may, still removes every copy, as `removeAll()`
    /// with `kSecMatchLimitAll` did.
    ///
    /// - Given: in `.everyGroup` mode, a plugin item and a client record, each stored both without a
    ///   group and under `group-x`
    /// - When: `removeAllExceptSessionRecords` runs over the unscoped store
    /// - Then:
    ///    - both copies of the plugin item are gone
    ///    - both copies of the client record are kept
    func testAccountInTwoGroupsIsRemovedFromBoth() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let clientAccount = sessionRecordAccounts[0]
        for store in [keychain.store(service: service), keychain.store(service: service, accessGroup: "group-x")] {
            try populate(store, with: ["authConfiguration", clientAccount])
        }

        try keychain.store(service: service).removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        XCTAssertEqual(try keychain.store(service: service).allAccounts(), [clientAccount, clientAccount])
        XCTAssertNil(keychain.value(service: service, account: "authConfiguration"))
        XCTAssertNil(keychain.value(service: service, accessGroup: "group-x", account: "authConfiguration"))
    }

    /// A failed removal is reported, not swallowed.
    ///
    /// - Given: a service holding a plugin item, whose removals fail
    /// - When: `removeAllExceptSessionRecords` runs over it
    /// - Then:
    ///    - it throws the removal error
    func testRemovalFailureIsThrown() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try populate(store, with: ["authConfiguration"])
        keychain.failing(.remove, with: errSecIO)

        XCTAssertThrowsError(try store.removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecIO))
        }
    }

    /// Only non-client items count towards "has items".
    ///
    /// - Given: an empty service, one holding only client records, and one holding a plugin item too
    /// - When: `hasItemsExceptSessionRecords` is asked of each
    /// - Then:
    ///    - only the one with a plugin item answers `true`
    func testHasItemsExceptSessionRecordsIgnoresClientRecords() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        XCTAssertFalse(try store.hasItemsExceptSessionRecords())

        try populate(store, with: sessionRecordAccounts + ["amplify.2.us-east-1_Pool.work.session"])
        XCTAssertFalse(try store.hasItemsExceptSessionRecords())

        try populate(store, with: ["authConfiguration"])
        XCTAssertTrue(try store.hasItemsExceptSessionRecords())
    }

    /// A failed listing is reported, never read as "no items".
    ///
    /// - Given: a service whose listing fails as a locked device's does
    /// - When: `hasItemsExceptSessionRecords` is asked
    /// - Then:
    ///    - it throws
    func testHasItemsExceptSessionRecordsThrowsWhenListingFails() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try populate(store, with: ["authConfiguration"])
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.hasItemsExceptSessionRecords())
    }

    /// When removals fail, the log says how many failed, not that items were removed.
    ///
    /// - Given: a service holding two plugin items and a client record, and removals of one plugin item
    ///   failing
    /// - When: `removeAllExceptSessionRecords` runs over it
    /// - Then:
    ///    - it throws
    ///    - no success message is logged
    ///    - one warning reports one failed removal, without naming the account
    func testFailedRemovalsAreCountedNotReportedAsSuccess() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try populate(store, with: ["authConfiguration", "amplify.us-east-1_Pool.session", sessionRecordAccounts[0]])
        keychain.failing(.remove, with: errSecIO, forAccount: "authConfiguration")
        let logger = RecordingLogger()

        XCTAssertThrowsError(try store.removeAllExceptSessionRecords(logger: logger, sparingDefaultSessionItems: true))

        XCTAssertFalse(logger.messages(at: .verbose).contains { $0.contains("Removed") })
        XCTAssertEqual(logger.messages(at: .warn).count, 1)
        XCTAssertTrue(logger.messages(at: .warn)[0].contains("1"))
        XCTAssertFalse(logger.messages(at: .warn)[0].contains("authConfiguration"))
        XCTAssertNil(keychain.value(service: service, account: "amplify.us-east-1_Pool.session"))
    }

    /// Records of later schema versions are spared too, and legacy plugin records are still removed.
    ///
    /// - Given: a service holding `amplify.2.` and `amplify.10.` client records, and the plugin's legacy
    ///   session records for a user pool and an identity pool
    /// - When: `removeAllExceptSessionRecords` runs over it
    /// - Then:
    ///    - the later-schema client records are kept
    ///    - the legacy plugin records are removed
    func testLaterSchemaVersionsAreSparedAndLegacyRecordsRemoved() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        let laterSchemaAccounts = [
            "amplify.2.us-east-1_Pool.work.session",
            "amplify.10.us-east-1_Pool.us-east-1:identity-pool.work.challenge"
        ]
        let legacyAccounts = [
            "amplify.us-east-1_x.session",
            "amplify.us-east-1:0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0.session"
        ]
        try populate(store, with: laterSchemaAccounts + legacyAccounts)

        try store.removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        XCTAssertEqual(try store.allAccounts(), laterSchemaAccounts.sorted())
    }

    /// Today's schema-1 records are recognised, in exactly the format the client writes.
    ///
    /// - Given: schema-1 accounts of both kinds, in every pool-namespace shape
    /// - When: each is classified
    /// - Then:
    ///    - every one is a client session record
    func testSchemaVersion1IsRecognised() {
        for account in sessionRecordAccounts {
            XCTAssertTrue(SessionRecordAccount.isClientSessionRecord(account), account)
        }
    }

    /// Every schema version is recognised, so a released plugin spares records from newer clients.
    ///
    /// - Given: accounts under schema versions 2, 10 and 123
    /// - When: each is classified
    /// - Then:
    ///    - every one is a client session record
    func testLaterSchemaVersionsAreRecognised() {
        for account in [
            "amplify.2.us-east-1_Pool.work.session",
            "amplify.10.us-east-1_Pool.us-east-1:identity-pool.work.challenge",
            "amplify.123.us-east-1:identity-pool.$default.session"
        ] {
            XCTAssertTrue(SessionRecordAccount.isClientSessionRecord(account), account)
        }
    }

    /// The plugin's accounts, and near misses, are not recognised.
    ///
    /// - Given: every plugin account shape, including legacy session records for a user pool and an
    ///   identity pool, and look-alikes of the client format
    /// - When: each is classified
    /// - Then:
    ///    - none is a client session record: the version must be one or more ASCII digits followed by `.`
    func testPluginAccountsAndLookAlikesAreNotRecognised() {
        let lookAlikes = [
            "amplify.us-east-1_x.session",
            "amplify.us-east-1:0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0.session",
            "amplify.1",
            "amplify.12",
            "amplify..pool.work.session",
            "amplify.1a.pool.work.session",
            "amplify.-1.pool.work.session",
            "amplify.\u{0661}.pool.work.session",
            "Amplify.1.pool.work.session",
            "xamplify.1.pool.work.session",
            "amplify",
            ""
        ]
        for account in pluginAccounts + lookAlikes {
            XCTAssertFalse(SessionRecordAccount.isClientSessionRecord(account), account)
        }
    }

    // MARK: The default session's items

    /// The default session's sidecar and challenge items are recognised in every namespace shape.
    ///
    /// - Given: `$default.meta` and `$default.challenge` accounts under a user pool, an identity pool and
    ///   both, with schema versions 1, 2 and 10
    /// - When: each is classified
    /// - Then:
    ///    - every one is a default-session item, and also a client session record
    func testDefaultSessionItemsAreRecognised() {
        let namespaces = [
            "us-east-1_Pool",
            "us-east-1:identity-pool",
            "us-east-1_Pool.us-east-1:identity-pool"
        ]
        for version in ["1", "2", "10"] {
            for namespace in namespaces {
                for kind in ["meta", "challenge"] {
                    let account = "amplify.\(version).\(namespace).$default.\(kind)"
                    XCTAssertTrue(SessionRecordAccount.isDefaultSessionItem(account), account)
                    XCTAssertTrue(SessionRecordAccount.isClientSessionRecord(account), account)
                }
            }
        }
    }

    /// The default session's two accounts are built for one namespace, the sidecar first.
    ///
    /// - Given: a user pool, an identity pool and a two-pool namespace
    /// - When: the accounts of the default session's two items are built for each
    /// - Then:
    ///    - they are `amplify.1.<namespace>.$default.meta` then `amplify.1.<namespace>.$default.challenge`, and both
    ///      are recognised as default-session items
    func testDefaultSessionItemAccountsAreBuiltForOneNamespace() {
        let namespaces = [
            "us-east-1_Pool",
            "us-east-1:identity-pool",
            "us-east-1_Pool.us-east-1:identity-pool"
        ]
        for namespace in namespaces {
            let accounts = SessionRecordAccount.defaultSessionItemAccounts(poolNamespace: namespace)
            XCTAssertEqual(accounts, ["amplify.1.\(namespace).$default.meta", "amplify.1.\(namespace).$default.challenge"])
            for account in accounts {
                XCTAssertTrue(SessionRecordAccount.isDefaultSessionItem(account), account)
            }
        }
    }

    /// Every other account is not a default-session item.
    ///
    /// - Given: a development build's leftover `$default.session`, a named session's items, a marker, the
    ///   plugin's own accounts, and near misses of the two suffixes
    /// - When: each is classified
    /// - Then:
    ///    - none is a default-session item
    func testOtherAccountsAreNotDefaultSessionItems() {
        let others = [
            "amplify.1.us-east-1_Pool.us-east-1:identity-pool.$default.session",
            "amplify.1.us-east-1_Pool.work.session",
            "amplify.1.us-east-1_Pool.work.challenge",
            "amplify.1.us-east-1_Pool.work.meta",
            "amplify.1.$default.0123456789abcdef.configuration",
            "amplify.1.$default.meta",
            "amplify.1..$default.meta",
            "amplify.1.us-east-1_Pool.$default.metadata",
            "amplify.1.us-east-1_Pool.$default.challenge.session",
            "amplify.1.us-east-1_Pool.default.meta",
            "amplify.us-east-1_Pool.$default.meta",
            "amplify.us-east-1_Pool.$default.challenge"
        ]
        for account in pluginAccounts + others {
            XCTAssertFalse(SessionRecordAccount.isDefaultSessionItem(account), account)
        }
    }

    /// A wipe of the plugin's session removes the default session's items and spares every other record.
    ///
    /// - Given: a service holding plugin items, client session records, and the default session's sidecar
    ///   and challenge items
    /// - When: `removeAllExceptSessionRecords` runs over it, not sparing the default session's items
    /// - Then:
    ///    - the plugin items and the default session's items are gone
    ///    - every other session record, a leftover `$default.session` included, is still there unchanged
    func testNotSparingDefaultSessionItemsRemovesThemAndSparesOtherRecords() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        let defaultSessionItems = [
            "amplify.1.us-east-1_Pool.us-east-1:identity-pool.$default.meta",
            "amplify.1.us-east-1_Pool.us-east-1:identity-pool.$default.challenge"
        ]
        let spared = sessionRecordAccounts.filter { !SessionRecordAccount.isDefaultSessionItem($0) }
        try populate(store, with: pluginAccounts + sessionRecordAccounts + defaultSessionItems)

        try store.removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: false)

        XCTAssertEqual(try store.allAccounts(), spared.sorted())
        for account in spared {
            XCTAssertEqual(keychain.value(service: service, account: account), Data(account.utf8), "\(account) should be kept")
        }
        XCTAssertTrue(spared.contains("amplify.1.us-east-1_Pool.$default.session"))
    }

    /// Asked to, the wipe spares the default session's items like any session record.
    ///
    /// - Given: a service holding plugin items and the default session's sidecar and challenge items
    /// - When: `removeAllExceptSessionRecords` runs over it with `sparingDefaultSessionItems: true`
    /// - Then:
    ///    - only the plugin items are gone
    func testDefaultSessionItemsAreSparedWhenAsked() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        let defaultSessionItems = [
            "amplify.1.us-east-1_Pool.$default.meta",
            "amplify.1.us-east-1_Pool.$default.challenge"
        ]
        try populate(store, with: pluginAccounts + defaultSessionItems)

        try store.removeAllExceptSessionRecords(logger: SilentLogger(), sparingDefaultSessionItems: true)

        XCTAssertEqual(try store.allAccounts(), defaultSessionItems.sorted())
    }

    private func populate(_ store: InMemoryKeychainItemStore, with accounts: [String]) throws {
        for account in accounts {
            try store.set(Data(account.utf8), key: account)
        }
    }
}
