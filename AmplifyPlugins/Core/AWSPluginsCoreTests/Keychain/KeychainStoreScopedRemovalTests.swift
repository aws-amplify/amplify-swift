//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(KeychainStore) @testable import AWSPluginsCore

/// `KeychainStore.removeAllExceptSessionRecords()` and the migrator's destination clear, which uses it.
/// Both run over the in-memory fake: `swift test` runs unsigned, so the real keychain is unavailable.
class KeychainStoreScopedRemovalTests: XCTestCase {

    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let accessGroup = "group"

    /// Every account the plugin writes, plus one it does not recognise.
    private let pluginAccounts = [
        "authConfiguration",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.session",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.alice.deviceMetadata",
        "amplify.us-east-1_Pool.us-east-1:identity-pool.Alice.deviceASF",
        "some.unrecognised.item"
    ]

    private let sessionRecordAccounts = [
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.session",
        "amplify.1.us-east-1_Pool.us-east-1:identity-pool.work.challenge"
    ]

    /// The test seam routes every member through the injected store, with the usual error mapping.
    ///
    /// - Given: a `KeychainStore` over the fake
    /// - When: a value is set, read, checked for and removed, and a missing key is read
    /// - Then:
    ///    - each operation reaches the fake, and a missing key is `KeychainStoreError.itemNotFound`
    func testInjectedItemStoreBacksEveryMember() throws {
        let keychain = InMemoryKeychain()
        let store = KeychainStore(service: sharedService, accessGroup: accessGroup, itemStore: keychain.store(service: sharedService, accessGroup: accessGroup))

        try store._set("value", key: "key")
        XCTAssertEqual(try store._getString("key"), "value")
        XCTAssertTrue(try store._hasItems())
        try store._remove("key")
        XCTAssertThrowsError(try store._getData("key")) { error in
            XCTAssertEqual(error as? KeychainStoreError, .itemNotFound)
        }
    }

    /// The store's scoped clear keeps session records.
    ///
    /// - Given: a store holding plugin items and client session records
    /// - When: `removeAllExceptSessionRecords()` runs
    /// - Then:
    ///    - the plugin items are gone and the session records are kept
    func testKeychainStoreScopedClearSparesSessionRecords() throws {
        let keychain = InMemoryKeychain()
        let store = makeStore(keychain)
        try populate(keychain, with: pluginAccounts + sessionRecordAccounts)

        try store.removeAllExceptSessionRecords()

        assertOnlySessionRecordsRemain(in: keychain)
    }

    /// The migrator clears its destination without deleting session records.
    ///
    /// - Given: a migration destination holding plugin items and client session records
    /// - When: the migrator clears the destination, as it does before moving items into it
    /// - Then:
    ///    - the plugin items are gone and the session records are kept
    func testMigratorDestinationClearSparesSessionRecords() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, with: pluginAccounts + sessionRecordAccounts)

        makeMigrator(keychain).clearDestination()

        assertOnlySessionRecordsRemain(in: keychain)
        XCTAssertFalse(keychain.mutations.contains(.removeAll(service: sharedService)))
    }

    /// If the destination cannot be listed, the migrator's clear removes nothing.
    ///
    /// - Given: a migration destination holding plugin items and session records, whose listing fails
    /// - When: the migrator clears the destination
    /// - Then:
    ///    - nothing is removed, plugin items included
    func testMigratorDestinationClearRemovesNothingWhenListingFails() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, with: pluginAccounts + sessionRecordAccounts)
        keychain.resetMutations()
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)

        makeMigrator(keychain).clearDestination()

        XCTAssertEqual(keychain.mutations, [])
        for account in pluginAccounts + sessionRecordAccounts {
            XCTAssertNotNil(keychain.value(service: sharedService, accessGroup: accessGroup, account: account), account)
        }
    }

    /// With no session records present, the migrator's clear still empties the destination.
    ///
    /// - Given: a migration destination holding only plugin items
    /// - When: the migrator clears the destination
    /// - Then:
    ///    - the destination is empty, as it always was after the clear
    func testMigratorDestinationClearWithoutSessionRecordsEmptiesTheDestination() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, with: pluginAccounts)

        makeMigrator(keychain).clearDestination()

        XCTAssertEqual(try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(), [])
    }

    /// The migrator moves the plugin's items and leaves client records where they are.
    ///
    /// - Given: an unshared source holding plugin items and client session records, and an empty
    ///   shared destination
    /// - When: `KeychainStoreMigrator.migrate()` runs
    /// - Then:
    ///    - the destination holds exactly the plugin items, and the source exactly the client records
    func testMigratorMovesPluginItemsAndLeavesSessionRecords() throws {
        let keychain = InMemoryKeychain()
        let source = keychain.store(service: "com.amplify.awsCognitoAuthPlugin")
        for account in pluginAccounts + sessionRecordAccounts {
            try source.set(Data(account.utf8), key: account)
        }

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(try source.allAccounts(), sessionRecordAccounts.sorted())
        XCTAssertEqual(
            try keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
    }

    /// The quiet store the migrator checks its destination through is the same store, logging at
    /// verbose only.
    ///
    /// - Given: a store over the real keychain, and one over the fake
    /// - When: their quiet stores are inspected
    /// - Then:
    ///    - the real one is a `KeychainItemStore` with the store's own attributes
    ///    - the fake-backed one is the injected fake
    func testQuietBackingStoreTargetsTheSameItems() {
        let store = KeychainStore(service: sharedService, accessGroup: accessGroup)
        XCTAssertEqual(
            (store.quietBackingStore as? KeychainItemStore)?.attributes,
            KeychainItemAttributes(service: sharedService, accessGroup: accessGroup)
        )
        XCTAssertTrue(makeStore(InMemoryKeychain()).quietBackingStore is InMemoryKeychainItemStore)
    }

    private func makeStore(_ keychain: InMemoryKeychain) -> KeychainStore {
        KeychainStore(
            service: sharedService,
            accessGroup: accessGroup,
            itemStore: keychain.store(service: sharedService, accessGroup: accessGroup)
        )
    }

    private func makeMigrator(_ keychain: InMemoryKeychain) -> KeychainStoreMigrator {
        KeychainStoreMigrator(
            oldService: "com.amplify.awsCognitoAuthPlugin",
            newService: sharedService,
            oldAccessGroup: nil,
            newAccessGroup: accessGroup,
            makeStore: { service, accessGroup in
                KeychainStore(service: service, accessGroup: accessGroup, itemStore: keychain.store(service: service, accessGroup: accessGroup))
            }
        )
    }

    private func populate(_ keychain: InMemoryKeychain, with accounts: [String]) throws {
        let store = keychain.store(service: sharedService, accessGroup: accessGroup)
        for account in accounts {
            try store.set(Data(account.utf8), key: account)
        }
    }

    private func assertOnlySessionRecordsRemain(in keychain: InMemoryKeychain, file: StaticString = #filePath, line: UInt = #line) {
        let remaining = try? keychain.store(service: sharedService, accessGroup: accessGroup).allAccounts()
        XCTAssertEqual(remaining, sessionRecordAccounts.sorted(), file: file, line: line)
        for account in sessionRecordAccounts {
            XCTAssertEqual(
                keychain.value(service: sharedService, accessGroup: accessGroup, account: account),
                Data(account.utf8),
                file: file,
                line: line
            )
        }
    }
}
