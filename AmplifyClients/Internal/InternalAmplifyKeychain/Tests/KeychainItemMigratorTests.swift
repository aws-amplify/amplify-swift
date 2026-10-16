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

    /// A run that skipped colliding items says so, and never reports a cleared destination or full success.
    ///
    /// - Given: a source holding every plugin item, and a destination that already holds every one of them
    ///   (and, in a second run, only one of them) because its clear did nothing
    /// - When: the migration runs
    /// - Then:
    ///    - its last verbose line counts the moved and the skipped items
    ///    - it logs neither "keychain under new access group is cleared" nor "Successfully migrated"
    func testARunWithCollisionsDoesNotReportSuccess() throws {
        for colliding in [pluginAccounts, [pluginAccounts.sorted()[1]]] {
            let keychain = InMemoryKeychain()
            try populate(keychain, source, with: pluginAccounts)
            try populate(keychain, destination, with: colliding)
            let logger = RecordingLogger()

            try makeMigrator(keychain, logger: logger).migrate(clearingDestinationWith: {})

            let verbose = logger.messages(at: .verbose)
            let moved = pluginAccounts.count - colliding.count
            XCTAssertEqual(
                verbose.last,
                "[KeychainStoreMigrator] Migrated \(moved) item(s); \(colliding.count) already existed in the destination and were not migrated"
            )
            XCTAssertFalse(verbose.contains { $0.contains("is cleared") || $0.contains("Successfully migrated") }, "\(colliding)")
            XCTAssertEqual(logger.messages(at: .warn).count, colliding.count)
        }
    }

    /// `willMove` runs once, after the destination clear has finished and before the first move, and also
    /// when there is nothing to clear.
    ///
    /// - Given: a source holding every plugin item, and a destination that holds a stale item (and, in a
    ///   second run, nothing)
    /// - When: the migration runs with a clear and a `willMove` that both record what they see
    /// - Then:
    ///    - with the stale item: the clear runs, then `willMove`, once, before any move
    ///    - with an empty destination: the clear does not run, and `willMove` still runs once, before any move
    func testWillMoveRunsAfterTheClearAndBeforeTheFirstMove() throws {
        for stale in [["amplify.us-east-1_Old.session"], []] {
            let keychain = InMemoryKeychain()
            try populate(keychain, source, with: pluginAccounts)
            try populate(keychain, destination, with: stale)
            let events = EventRecorder()
            keychain.beforeMove { account in events.append("move \(account)") }

            try makeMigrator(keychain).migrate(
                clearingDestinationWith: { events.append("clear") },
                willMove: { events.append("willMove") }
            )

            let moves = pluginAccounts.sorted().map { "move \($0)" }
            XCTAssertEqual(events.all, (stale.isEmpty ? [] : ["clear"]) + ["willMove"] + moves, "\(stale)")
        }
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

    /// An account stored in two access groups moves once; the other copy collides and stays behind.
    ///
    /// Which copy moves is the one listed first, and the keychain does not specify that order, so this
    /// only checks that one copy moved and the other stayed, whichever they are.
    ///
    /// - Given: in `.everyGroup` mode, an unscoped source holding every plugin item, with
    ///   `authConfiguration` stored both without a group and under `group-x`
    /// - When: the migration runs
    /// - Then:
    ///    - the destination holds every plugin item, `authConfiguration` being one of the two copies
    ///    - the other copy is still in the source, under its own group, and nothing else is
    func testAccountInTwoGroupsMovesOneCopy() throws {
        let keychain = InMemoryKeychain(unscopedMatching: .everyGroup)
        let ungroupedCopy = Data("\(source.service)/authConfiguration".utf8)
        let groupXCopy = Data("group-x".utf8)
        try populate(keychain, source, with: pluginAccounts)
        try keychain.store(service: source.service, accessGroup: "group-x").set(groupXCopy, key: "authConfiguration")

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            pluginAccounts.sorted()
        )
        let moved = try XCTUnwrap(value(keychain, destination, "authConfiguration"))
        let left = [
            keychain.value(service: source.service, account: "authConfiguration"),
            keychain.value(service: source.service, accessGroup: "group-x", account: "authConfiguration")
        ].compactMap { $0 }
        XCTAssertEqual(left.count, 1)
        XCTAssertEqual(Set(left + [moved]), [ungroupedCopy, groupXCopy])
        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), ["authConfiguration"])
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

    /// The default session's sidecar and challenge items move with the plugin's record; every other client
    /// record stays.
    ///
    /// - Given: a source holding plugin items, the default session's `$default.meta` and `$default.challenge`,
    ///   a named session's `work.session` and `work.challenge`, and a leftover `$default.session`
    /// - When: the migration runs
    /// - Then:
    ///    - the plugin items and the two default-session items are in the destination with their bytes
    ///    - the named session's records and the leftover are still in the source, and not in the destination
    func testDefaultSessionItemsMoveAndOtherClientRecordsStay() throws {
        let keychain = InMemoryKeychain()
        let defaultSessionItems = [
            "amplify.1.us-east-1_Pool.$default.meta",
            "amplify.1.us-east-1_Pool.$default.challenge"
        ]
        let staying = [
            "amplify.1.us-east-1_Pool.work.session",
            "amplify.1.us-east-1_Pool.work.challenge",
            "amplify.1.us-east-1_Pool.$default.session"
        ]
        try populate(keychain, source, with: pluginAccounts + defaultSessionItems + staying)

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), staying.sorted())
        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            (pluginAccounts + defaultSessionItems).sorted()
        )
        for account in defaultSessionItems {
            XCTAssertEqual(value(keychain, destination, account), Data("\(source.service)/\(account)".utf8), account)
        }
        for account in staying {
            XCTAssertEqual(value(keychain, source, account), Data("\(source.service)/\(account)".utf8), account)
        }
    }

    /// The destination clear removes the default session's two items, as the move does, and spares every
    /// other client record.
    ///
    /// - Given: a source holding plugin items and the default session's `$default.meta`; a destination
    ///   holding a stale plugin item, its own `$default.meta` and `$default.challenge`, a named session's
    ///   `work.session` and a leftover `$default.session`
    /// - When: the migration runs
    /// - Then:
    ///    - the destination's `$default.meta` is the source's: the stale one was cleared, so the source's moved
    ///    - the destination's `$default.challenge` is gone: the clear removed it and the source had none
    ///    - the named session's record and the leftover are still in the destination with their own bytes
    ///    - the source is empty
    func testDestinationClearRemovesTheDefaultSessionItemsAndSparesOtherClientRecords() throws {
        let keychain = InMemoryKeychain()
        let meta = "amplify.1.us-east-1_Pool.$default.meta"
        let challenge = "amplify.1.us-east-1_Pool.$default.challenge"
        let spared = ["amplify.1.us-east-1_Pool.work.session", "amplify.1.us-east-1_Pool.$default.session"]
        try populate(keychain, source, with: pluginAccounts + [meta])
        try populate(keychain, destination, with: ["amplify.us-east-1_Old.session", meta, challenge] + spared)

        try makeMigrator(keychain).migrate()

        XCTAssertEqual(
            try keychain.store(service: destination.service, accessGroup: destination.accessGroup).allAccounts(),
            (pluginAccounts + [meta] + spared).sorted()
        )
        XCTAssertEqual(value(keychain, destination, meta), Data("\(source.service)/\(meta)".utf8))
        XCTAssertNil(value(keychain, destination, challenge))
        for account in spared {
            XCTAssertEqual(value(keychain, destination, account), Data("\(destination.service)/\(account)".utf8), account)
        }
        XCTAssertEqual(try keychain.store(service: source.service).allAccounts(), [])
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

    /// Records events in order, from the migrator's closures and the keychain's hooks.
    private final class EventRecorder: @unchecked Sendable {
        // `@unchecked Sendable`: `events` is only touched while holding `lock`.
        private let lock = NSLock()
        private var events: [String] = []

        var all: [String] {
            lock.lock()
            defer { lock.unlock() }
            return events
        }

        func append(_ event: String) {
            lock.lock()
            defer { lock.unlock() }
            events.append(event)
        }
    }

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
