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

/// The access-group migration, over the in-memory fake: `swift test` runs unsigned, so the real keychain
/// is unavailable.
final class KeychainItemMigratorTests: XCTestCase {

    private let source = KeychainItemAttributes(service: "com.amplify.awsCognitoAuthPlugin")
    private let destination = KeychainItemAttributes(service: "com.amplify.awsCognitoAuthPluginShared", accessGroup: "group")

    private let pluginAccounts = [
        "authConfiguration",
        "amplify.us-east-1_Pool.session",
        "amplify.us-east-1_Pool.alice.deviceMetadata",
        "amplify.us-east-1_Pool.Alice.deviceASF"
    ]

    /// Every plugin item moves to the destination with its data, and leaves the source.
    ///
    /// - Given: a source holding every kind of plugin item, and an empty destination
    /// - When: the migration runs
    /// - Then:
    ///    - every item is in the destination with its bytes unchanged, and the source is empty
    func testMovesEveryPluginItemWithItsData() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, source, with: pluginAccounts)

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), [])
        for account in pluginAccounts {
            XCTAssertEqual(value(keychain, destination, account), Data("\(source.service)/\(account)".utf8), account)
        }
    }

    /// A non-empty destination is cleared before the move, so the source's items replace it.
    ///
    /// - Given: a destination holding a stale configuration record and a stale extra item
    /// - When: the migration runs
    /// - Then:
    ///    - the destination holds exactly the source's items, with the source's bytes
    func testClearsANonEmptyDestinationFirst() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, source, with: pluginAccounts)
        try populate(keychain, destination, with: ["authConfiguration", "amplify.us-east-1_Old.session"])

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(), pluginAccounts.sorted())
        XCTAssertEqual(value(keychain, destination, "authConfiguration"), Data("\(source.service)/authConfiguration".utf8))
    }

    /// If the source cannot be listed, nothing moves and the error is thrown.
    ///
    /// - Given: a source whose listing fails as a locked device's does
    /// - When: the migration runs
    /// - Then:
    ///    - it throws the listing error, and every source item is still in the source
    func testListingFailureMovesNothing() throws {
        let keychain = InMemoryKeychain()
        try populate(keychain, source, with: pluginAccounts)
        keychain.failing(.listAccounts, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try makeMigrator(keychain).migrate()) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
        for account in pluginAccounts {
            XCTAssertNotNil(value(keychain, source, account), account)
        }
    }

    /// A collision skips only the colliding account: every other account still moves, and nothing throws.
    ///
    /// - Given: a source holding every plugin item, and a destination that still holds the second one in
    ///   listing order because its clear did nothing
    /// - When: the migration runs
    /// - Then:
    ///    - it does not throw
    ///    - every other account is in the destination and gone from the source
    ///    - the colliding account is still in the source, and the destination's copy is untouched
    ///    - one warning is logged, and it does not name the account
    func testCollisionInTheMiddleSkipsOnlyThatAccount() throws {
        let keychain = InMemoryKeychain()
        let colliding = pluginAccounts.sorted()[1]
        try populate(keychain, source, with: pluginAccounts)
        try populate(keychain, destination, with: [colliding])
        let logger = RecordingLogger()

        try makeMigrator(keychain, logger: logger).migrate(clearingDestinationWith: {})

        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), [colliding])
        XCTAssertEqual(value(keychain, source, colliding), Data("\(source.service)/\(colliding)".utf8))
        XCTAssertEqual(value(keychain, destination, colliding), Data("\(destination.service)/\(colliding)".utf8))
        for account in pluginAccounts where account != colliding {
            XCTAssertEqual(value(keychain, destination, account), Data("\(source.service)/\(account)".utf8), account)
        }
        XCTAssertEqual(logger.messages(at: .warn).count, 1)
        XCTAssertFalse(logger.messages(at: .warn).joined().contains(colliding))
    }

    /// Any other move failure part-way stops the migration and throws, leaving the earlier moves done.
    ///
    /// - Given: a source holding every plugin item, whose move of the second account in listing order
    ///   fails
    /// - When: the migration runs
    /// - Then:
    ///    - it throws the move error
    ///    - the first account is in the destination
    ///    - the failing account and every later one are still in the source
    func testMoveFailurePartWayStopsAndThrows() throws {
        let keychain = InMemoryKeychain()
        let ordered = pluginAccounts.sorted()
        try populate(keychain, source, with: pluginAccounts)
        keychain.failing(.move, with: errSecIO, forAccount: ordered[1])

        XCTAssertThrowsError(try makeMigrator(keychain).migrate()) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecIO))
        }

        XCTAssertEqual(try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(), [ordered[0]])
        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), Array(ordered.dropFirst()))
    }

    /// A failed listing or move is logged once, by the store that saw the status, not again here.
    ///
    /// - Given: a migration whose move fails, and one whose listing fails
    /// - When: each runs
    /// - Then:
    ///    - each throws, and the migrator itself logs nothing at error or warn level
    func testFailuresAreLoggedOnceByTheStore() throws {
        for operation in [InMemoryKeychain.Operation.move, .listAccounts] {
            let keychain = InMemoryKeychain()
            try populate(keychain, source, with: pluginAccounts)
            keychain.failing(operation, with: errSecIO)
            let logger = RecordingLogger()

            XCTAssertThrowsError(try makeMigrator(keychain, logger: logger).migrate(clearingDestinationWith: {}))

            XCTAssertEqual(logger.messages(at: .error), [], "\(operation)")
            XCTAssertEqual(logger.messages(at: .warn), [], "\(operation)")
        }
    }

    /// Moving to a destination without an access group keeps each item's own group, as on a device.
    ///
    /// The real move sets `kSecAttrAccessGroup` only when the destination has one
    /// (`moveAttributes(to:)`), so an item moved from the shared service to the unshared one keeps the
    /// shared group.
    ///
    /// - Given: a shared source under an access group holding plugin items, and an ungrouped destination
    /// - When: the migration runs
    /// - Then:
    ///    - every item is under the destination service and still under the source's access group
    ///    - nothing is under the destination service without a group
    func testSharedToUnsharedKeepsTheItemsAccessGroup() throws {
        let keychain = InMemoryKeychain()
        let migrator = KeychainItemMigrator(
            source: destination,
            destination: source,
            sourceStore: keychain.store(service: destination.service, accessGroup: destination.accessGroup),
            destinationStore: keychain.store(service: source.service, accessGroup: source.accessGroup),
            logger: SilentLogger()
        )
        try populate(keychain, destination, with: pluginAccounts)

        try migrator.migrate()

        XCTAssertEqual(try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(), [])
        XCTAssertEqual(try keychain.store(service: source.service, accessGroup: destination.accessGroup).allAccounts(), pluginAccounts.sorted())
        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), [])
    }

    /// An account stored in two access groups moves once; the second copy collides and stays behind.
    ///
    /// - Given: in `.everyGroup` mode, an unscoped source holding every plugin item, with
    ///   `authConfiguration` stored both without a group and under `group-x`
    /// - When: the migration runs
    /// - Then:
    ///    - the destination holds every plugin item, `authConfiguration` being the ungrouped copy
    ///    - the `group-x` copy is still in the source, and nothing else is
    func testAccountInTwoGroupsMovesOneCopy() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        try populate(keychain, source, with: pluginAccounts)
        try keychain.store(service: source.service, accessGroup: "group-x").set(Data("group-x".utf8), key: "authConfiguration")

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        XCTAssertEqual(value(keychain, destination, "authConfiguration"), Data("\(source.service)/authConfiguration".utf8))
        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), ["authConfiguration"])
        XCTAssertEqual(keychain.value(service: source.service, accessGroup: "group-x", account: "authConfiguration"), Data("group-x".utf8))
    }

    // MARK: Client session records

    /// Client session records are never moved: the client scopes its records by access group itself.
    ///
    /// - Given: a source holding plugin items and client records of schema versions 1 and 2
    /// - When: the migration runs
    /// - Then:
    ///    - every plugin item is in the destination
    ///    - every client record is still in the source with its own bytes, and none is in the destination
    func testClientRecordsAreNotMoved() throws {
        let keychain = InMemoryKeychain()
        let clientAccounts = [
            "amplify.1.us-east-1_Pool.work.session",
            "amplify.1.us-east-1_Pool.work.challenge",
            "amplify.2.us-east-1_Pool.work.session"
        ]
        try populate(keychain, source, with: pluginAccounts + clientAccounts)

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), clientAccounts.sorted())
        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        for account in clientAccounts {
            XCTAssertEqual(value(keychain, source, account), Data("\(source.service)/\(account)".utf8), account)
        }
    }

    /// The same client account in source and destination no longer abandons the migration.
    ///
    /// Before client records were excluded, the destination's clear spared the destination's copy, the
    /// source's copy then collided with it, and the whole migration was abandoned on
    /// `errSecDuplicateItem`, leaving the plugin's items behind.
    ///
    /// - Given: a source and a destination that both hold the same client account, and a source holding
    ///   every plugin item
    /// - When: the migration runs
    /// - Then:
    ///    - every plugin item is in the destination
    ///    - each copy of the client record is untouched where it was
    func testSameClientAccountInSourceAndDestinationDoesNotBlockMigration() throws {
        let keychain = InMemoryKeychain()
        let clientAccount = "amplify.1.us-east-1_Pool.work.session"
        try populate(keychain, source, with: pluginAccounts + [clientAccount])
        try populate(keychain, destination, with: [clientAccount, "amplify.us-east-1_Old.session"])

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            (pluginAccounts + [clientAccount]).sorted()
        )
        XCTAssertEqual(value(keychain, source, clientAccount), Data("\(source.service)/\(clientAccount)".utf8))
        XCTAssertEqual(value(keychain, destination, clientAccount), Data("\(destination.service)/\(clientAccount)".utf8))
        XCTAssertFalse(keychain.mutations.contains(.move(
            service: source.service,
            account: clientAccount,
            toService: destination.service
        )))
    }

    // MARK: Helpers

    private func makeMigrator(_ keychain: InMemoryKeychain, logger: any Logger = SilentLogger()) -> KeychainItemMigrator {
        KeychainItemMigrator(
            source: source,
            destination: destination,
            sourceStore: keychain.store(service: source.service, accessGroup: source.accessGroup),
            destinationStore: keychain.store(service: destination.service, accessGroup: destination.accessGroup),
            logger: logger
        )
    }

    /// Stores each account with the bytes `<service>/<account>`, so a test can tell which copy it reads.
    private func populate(_ keychain: InMemoryKeychain, _ attributes: KeychainItemAttributes, with accounts: [String]) throws {
        let store = keychain.store(service: attributes.service, accessGroup: attributes.accessGroup)
        for account in accounts {
            try store.set(Data("\(attributes.service)/\(account)".utf8), key: account)
        }
    }

    private func value(_ keychain: InMemoryKeychain, _ attributes: KeychainItemAttributes, _ account: String) -> Data? {
        keychain.value(service: attributes.service, accessGroup: attributes.accessGroup, account: account)
    }
}
