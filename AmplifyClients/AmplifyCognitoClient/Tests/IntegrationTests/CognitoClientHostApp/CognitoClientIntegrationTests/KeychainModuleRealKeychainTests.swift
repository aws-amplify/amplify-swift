//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
@testable import InternalAmplifyKeychain
import Security
import XCTest

/// Parity `KM-1` … `KM-11`: the plugin's `ScopedWipeRealKeychainTests` (its real-keychain questions Q1–Q3,
/// Q5 and Q6), ported verbatim into the client's host app. Each test keeps the plugin's
/// method name, so parity is checkable by name.
///
/// The code under test is the real `InternalAmplifyKeychain` (`KeychainItemStore`,
/// `KeychainItemAttributes`, `KeychainItemMigrator`, `removeAllExceptSessionRecords`), the module the
/// client stores its session records through. This target reaches it through the `AmplifyCognitoClient`
/// product, not through the plugin: nothing here links `Amplify` or `AWSCognitoAuthPlugin`. Its API is
/// `package`; `@testable import` reaches it from this Xcode target, which lies outside the SPM package,
/// because Debug package builds enable testability. No sandbox configuration and no network are used.
///
/// Every test works on two services unique to it, both wiped in `tearDown`, so the sessions the other
/// suites store under `com.amplify.awsCognitoAuthPlugin` are never touched. Where the in-memory fake
/// (`InMemoryKeychain`, `.everyGroup` mode) or the keychain module assumes a behaviour, the test asserts
/// that assumption, so a contradiction fails. Observations are printed with a `[RealKeychain]` prefix.
///
/// Not ported: `testQ4BeforeFirstUnlockNeedsADevice` (a simulator is never locked). It is left to a
/// manual check on a locked device.
final class KeychainModuleRealKeychainTests: ClientIntegrationTestCase {

    private var source = ""
    private var destination = ""
    private var defaultGroup = ""
    private var sharedGroup = ""

    override func setUpWithError() throws {
        try super.setUpWithError()
        let id = UUID().uuidString
        source = "com.amplify.keychainWipeProbe.\(id)"
        destination = "com.amplify.keychainWipeProbe.\(id).Shared"
        defaultGroup = try RealKeychain.defaultGroup()
        sharedGroup = RealKeychain.sharedGroup(defaultGroup: defaultGroup)
    }

    override func tearDown() {
        RealKeychain.wipe(source)
        RealKeychain.wipe(destination)
        super.tearDown()
    }

    // MARK: - Q1

    /// KM-1. Q1: a single-account move onto an occupied destination is `errSecDuplicateItem` and changes
    /// nothing, which `KeychainItemStore.moveOutcome` maps to `.destinationOccupied`.
    ///
    /// - Given: `authConfiguration` in the source service (default group), and the same account already
    ///   in the destination service under the shared group
    /// - When:
    ///    - the per-account `SecItemUpdate` `KeychainItemStore.move` issues runs, once raw and once
    ///      through `move(_:to:)`
    /// - Then:
    ///    - the raw status is `errSecDuplicateItem` (-25299), and `move` returns `.destinationOccupied`
    ///    - both items are untouched, each in its own service and group with its own data
    ///
    func testQ1SingleAccountMoveOntoOccupiedDestinationIsDuplicateItem() throws {
        let account = "authConfiguration"
        XCTAssertEqual(RealKeychain.add("source", account: account, service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("destination", account: account, service: destination, group: sharedGroup), errSecSuccess)
        let sourceAttributes = KeychainItemAttributes(service: source)
        let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: sharedGroup)
        let before = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)

        let status = SecItemUpdate(
            sourceAttributes.itemQuery(account: account) as CFDictionary,
            sourceAttributes.moveAttributes(to: destinationAttributes) as CFDictionary
        )
        let afterRaw = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)
        RealKeychain.report(self, "raw per-account move onto occupied destination: \(RealKeychain.describe(status)); after \(afterRaw)")
        XCTAssertEqual(status, errSecDuplicateItem, "Q1 observed \(RealKeychain.describe(status)), expected errSecDuplicateItem")
        XCTAssertEqual(afterRaw, before, "Q1: a colliding move changed an item: \(before) -> \(afterRaw)")

        let outcome = try KeychainItemStore(attributes: sourceAttributes, logger: AmplifyLogging.logger(for: Self.self))
            .move(account, to: destinationAttributes)
        let afterMove = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)
        RealKeychain.report(self, "KeychainItemStore.move outcome: \(outcome); after \(afterMove)")
        XCTAssertEqual(outcome, .destinationOccupied, "Q1: move(_:to:) returned \(outcome)")
        XCTAssertEqual(afterMove, before, "Q1: move(_:to:) changed an item: \(before) -> \(afterMove)")
    }

    /// KM-2. Q1, the other direction: a move to a destination **without** an access group collides only
    /// with a destination item in the moving item's own group.
    ///
    /// - Given: `authConfiguration` in the source service under the shared group, and in the
    ///   destination service under the shared group too
    /// - When:
    ///    - the source store (scoped to the shared group) moves it to the ungrouped destination
    /// - Then:
    ///    - the outcome is `.destinationOccupied` and nothing changes
    ///
    func testQ1MoveToUngroupedDestinationCollidesInTheItemsOwnGroup() throws {
        let account = "authConfiguration"
        XCTAssertEqual(RealKeychain.add("source", account: account, service: source, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("destination", account: account, service: destination, group: sharedGroup), errSecSuccess)
        let before = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)

        let outcome = try KeychainItemStore(service: source, accessGroup: sharedGroup)
            .move(account, to: KeychainItemAttributes(service: destination))
        let after = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)
        RealKeychain.report(self, "move to ungrouped destination occupied in the same group: \(outcome); after \(after)")
        XCTAssertEqual(outcome, .destinationOccupied, "Q1b: move(_:to:) returned \(outcome); after \(after)")
        XCTAssertEqual(after, before, "Q1b: a colliding move changed an item: \(before) -> \(after)")
    }

    // MARK: - Q2

    /// KM-3. Q2, the OS behaviour (a characterisation, kept after the fix): an **unscoped** per-account move of
    /// an account stored in two groups moves neither copy.
    ///
    /// This is what stranded the account before the fix (`fix/auth-keychain-move-by-group`). The unscoped
    /// `move(_:to:)` is unchanged, so it still shows it; the migrator no longer uses it for listed items.
    ///
    /// - Given: `authConfiguration` in the source service under the default group ("default") and the
    ///   shared group ("shared")
    /// - When:
    ///    - the unscoped per-account `SecItemUpdate` to (destination, shared group), then to
    ///      (destination, default group), runs raw and through `KeychainItemStore.move(_:to:)`
    /// - Then (observed on iOS 26.5):
    ///    - every attempt is `errSecDuplicateItem` / `.destinationOccupied`, even though the destination
    ///      is empty: the two matched copies would collide with each other
    ///    - neither copy changes, and the destination stays empty
    ///
    func testQ2UnscopedMoveOfAccountInTwoGroupsMovesNeitherCopy() throws {
        let account = "authConfiguration"
        XCTAssertEqual(RealKeychain.add("default", account: account, service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: account, service: source, group: sharedGroup), errSecSuccess)
        let sourceAttributes = KeychainItemAttributes(service: source)
        let store = KeychainItemStore(attributes: sourceAttributes, logger: AmplifyLogging.logger(for: Self.self))
        let before = RealKeychain.rows(service: source)

        for group in [sharedGroup, defaultGroup] {
            let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: group)
            let rawStatus = SecItemUpdate(
                sourceAttributes.itemQuery(account: account) as CFDictionary,
                sourceAttributes.moveAttributes(to: destinationAttributes) as CFDictionary
            )
            let afterRaw = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)
            let outcome = try store.move(account, to: destinationAttributes)
            let afterMove = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)
            let observed = "to \(group): raw \(RealKeychain.describe(rawStatus)) -> \(afterRaw); "
                + "move(_:to:) \(outcome) -> \(afterMove)"
            RealKeychain.report(self, "unscoped move of a two-group account: \(observed)")

            XCTAssertEqual(rawStatus, errSecDuplicateItem, "Q2 OS behaviour: \(observed)")
            XCTAssertEqual(outcome, .destinationOccupied, "Q2 OS behaviour: \(observed)")
            XCTAssertEqual(afterRaw, before, "Q2 OS behaviour: \(observed)")
            XCTAssertEqual(afterMove, before, "Q2 OS behaviour: \(observed)")
        }
    }

    /// KM-4. Q2, fixed: entry-scoped moves of an account stored in two groups, to the shared group.
    ///
    /// - Given: `authConfiguration` in the source service under the default and the shared group
    /// - When:
    ///    - the unscoped store lists it with `allEntries()`, and each entry is moved with
    ///      `move(_ entry:to:)` to (destination, shared group), as the migrator now does
    /// - Then:
    ///    - the listing has two entries, one per group
    ///    - the first move is `.moved` and the second `.destinationOccupied`
    ///    - one copy is in the destination and the other is still in the source
    ///
    func testQ2EntryScopedMoveOfAccountInTwoGroupsToTheSharedGroup() throws {
        try assertEntryScopedTwoGroupMove(toGroup: sharedGroup)
    }

    /// KM-5. Q2, fixed, with the destination group being the default group instead: the same outcome.
    ///
    /// - Given: `authConfiguration` in the source service under the default and the shared group
    /// - When:
    ///    - each listed entry is moved to (destination, default group)
    /// - Then:
    ///    - one copy moves and one stays, as in `testQ2EntryScopedMoveOfAccountInTwoGroupsToTheSharedGroup`
    ///
    func testQ2EntryScopedMoveOfAccountInTwoGroupsToTheDefaultGroup() throws {
        try assertEntryScopedTwoGroupMove(toGroup: defaultGroup)
    }

    /// KM-6. Q2 through the migrator, fixed: an account in two groups reaches the destination.
    ///
    /// - Given: an unscoped source holding plugin items in the default group, `authConfiguration` also
    ///   under the shared group, and a v1 client record
    /// - When:
    ///    - `KeychainItemMigrator` over real stores migrates to (destination, shared group)
    /// - Then:
    ///    - every plugin account is in the destination exactly once, `authConfiguration` included
    ///    - exactly one `authConfiguration` copy is left in the source, beside the client record
    ///
    func testQ2MigratorWithAccountInTwoGroups() throws {
        let plugin = ["amplify.us-east-1_Probe.session", "authConfiguration"]
        let client = "amplify.1.us-east-1_Probe.work.session"
        for account in plugin + [client] {
            XCTAssertEqual(RealKeychain.add("default", account: account, service: source), errSecSuccess)
        }
        XCTAssertEqual(RealKeychain.add("shared", account: "authConfiguration", service: source, group: sharedGroup), errSecSuccess)

        let logger = AmplifyLogging.logger(for: Self.self)
        let sourceAttributes = KeychainItemAttributes(service: source)
        let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: sharedGroup)
        try KeychainItemMigrator(
            source: sourceAttributes,
            destination: destinationAttributes,
            sourceStore: KeychainItemStore(attributes: sourceAttributes, logger: logger),
            destinationStore: KeychainItemStore(attributes: destinationAttributes, logger: logger),
            logger: logger
        ).migrate()

        let inSource = RealKeychain.rows(service: source)
        let inDestination = RealKeychain.rows(service: destination)
        RealKeychain.report(self, "migrator, account in two groups: source \(inSource); destination \(inDestination)")
        XCTAssertEqual(
            inDestination.map(\.account),
            plugin.sorted(),
            "Q2 migrator: destination holds \(inDestination); source holds \(inSource)"
        )
        XCTAssertEqual(Set(inDestination.map(\.group)), [sharedGroup], "Q2 migrator: destination holds \(inDestination)")
        XCTAssertEqual(
            inSource.map(\.account),
            ["amplify.1.us-east-1_Probe.work.session", "authConfiguration"],
            "Q2 migrator: source holds \(inSource); destination holds \(inDestination)"
        )
    }

    private func assertEntryScopedTwoGroupMove(toGroup group: String) throws {
        let account = "authConfiguration"
        XCTAssertEqual(RealKeychain.add("default", account: account, service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: account, service: source, group: sharedGroup), errSecSuccess)
        let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: group)
        let store = KeychainItemStore(service: source)

        let entries = try store.allEntries()
        XCTAssertEqual(
            Set(entries),
            [KeychainEntry(account: account, accessGroup: defaultGroup), KeychainEntry(account: account, accessGroup: sharedGroup)],
            "Q2 fixed: allEntries() returned \(entries)"
        )
        var outcomes: [KeychainMoveOutcome] = []
        for entry in entries {
            try outcomes.append(store.move(entry, to: destinationAttributes))
        }
        let inSource = RealKeychain.rows(service: source)
        let inDestination = RealKeychain.rows(service: destination)
        let observed = "to \(group): entries \(entries.map { $0.accessGroup ?? "nil" }); outcomes \(outcomes); "
            + "source \(inSource); destination \(inDestination)"
        RealKeychain.report(self, "entry-scoped move of a two-group account: \(observed)")

        XCTAssertEqual(outcomes, [.moved, .destinationOccupied], "Q2 fixed: \(observed)")
        XCTAssertEqual(inDestination.map(\.account), [account], "Q2 fixed: \(observed)")
        XCTAssertEqual(inDestination.map(\.group), [group], "Q2 fixed: \(observed)")
        XCTAssertEqual(inSource.map(\.account), [account], "Q2 fixed: \(observed)")
        XCTAssertEqual(
            Set(inSource + inDestination).map(\.value).sorted(),
            ["default", "shared"],
            "Q2 fixed: a copy lost its data: \(observed)"
        )
    }

    // MARK: - Q3

    /// KM-7. Q3 (iOS only): an unscoped per-account delete removes the account from every group.
    ///
    /// macOS cannot be tested from this host app; the review's question was about the macOS
    /// data-protection keychain.
    ///
    /// - Given: `authConfiguration` in the default and the shared group of one service
    /// - When:
    ///    - `KeychainItemStore(service:).remove` runs once, then again
    /// - Then:
    ///    - the first removal leaves no copy (iOS removes every match without `kSecMatchLimit`)
    ///    - the second, finding nothing, still succeeds, which the scoped clear relies on when it
    ///      removes an account once per listed row
    ///
    func testQ3UnscopedDeleteRemovesEveryGroupsCopy() throws {
        let account = "authConfiguration"
        XCTAssertEqual(RealKeychain.add("default", account: account, service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: account, service: source, group: sharedGroup), errSecSuccess)
        let store = KeychainItemStore(service: source)

        let rawStatus = SecItemDelete(KeychainItemAttributes(service: source).itemQuery(account: account) as CFDictionary)
        let remaining = RealKeychain.rows(service: source)
        RealKeychain.report(self, "unscoped per-account delete of a two-group account: \(RealKeychain.describe(rawStatus)); remaining \(remaining)")
        XCTAssertEqual(rawStatus, errSecSuccess, "Q3: \(RealKeychain.describe(rawStatus))")
        XCTAssertEqual(remaining, [], "Q3: one unscoped delete left \(remaining)")

        XCTAssertNoThrow(try store.remove(account), "Q3: removing an absent account threw")
    }

    /// KM-8. Q3 through the scoped clear: every plugin copy goes, in every group; client records stay.
    ///
    /// - Given: one service holding plugin accounts in the default group, `authConfiguration` also in
    ///   the shared group, and v1/v2 client records in both groups
    /// - When:
    ///    - `removeAllExceptSessionRecords` runs on an unscoped store
    /// - Then:
    ///    - no plugin account is left in either group
    ///    - every client record is left, in its own group, with its own data
    ///
    func testQ3ScopedClearRemovesEveryPluginCopyAndKeepsClientRecords() throws {
        let plugin = ["amplify.us-east-1_Probe.session", "amplify.us-east-1_Probe.alice.deviceMetadata", "authConfiguration"]
        let clientDefault = "amplify.1.us-east-1_Probe.work.session"
        let clientShared = "amplify.2.us-east-1_Probe.work.session"
        for account in plugin + [clientDefault] {
            XCTAssertEqual(RealKeychain.add("default", account: account, service: source), errSecSuccess)
        }
        XCTAssertEqual(RealKeychain.add("shared", account: "authConfiguration", service: source, group: sharedGroup), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: clientShared, service: source, group: sharedGroup), errSecSuccess)
        let expected = RealKeychain.rows(service: source).filter { $0.account.hasPrefix("amplify.1.") || $0.account.hasPrefix("amplify.2.") }

        try KeychainItemStore(service: source).removeAllExceptSessionRecords(logger: AmplifyLogging.logger(for: Self.self), sparingDefaultSessionItems: true)

        let after = RealKeychain.rows(service: source)
        RealKeychain.report(self, "scoped clear over two groups: left \(after)")
        XCTAssertEqual(after, expected, "Q3 scoped clear: left \(after)")
    }

    // MARK: - Q5

    /// KM-9. Q5: a shared→unshared migration leaves each moved item in its own group, and the unshared
    /// store's unscoped queries still find it. The in-memory fake models this too.
    ///
    /// - Given: plugin items and a client record in the shared service under the shared group
    /// - When:
    ///    - `KeychainItemMigrator` over real stores moves them to the unshared service, which has no
    ///      access group (as the plugin does when the access group is removed)
    /// - Then:
    ///    - every plugin item is in the unshared service, still in the shared group
    ///    - an unscoped `getData` and `allAccounts` on the unshared service find them
    ///    - the client record is still in the shared service
    ///
    func testQ5SharedToUnsharedKeepsEachItemsGroup() throws {
        let plugin = ["amplify.us-east-1_Probe.session", "authConfiguration"]
        let client = "amplify.1.us-east-1_Probe.work.session"
        for account in plugin + [client] {
            XCTAssertEqual(RealKeychain.add(account, account: account, service: destination, group: sharedGroup), errSecSuccess)
        }
        let logger = AmplifyLogging.logger(for: Self.self)
        let sharedAttributes = KeychainItemAttributes(service: destination, accessGroup: sharedGroup)
        let unsharedAttributes = KeychainItemAttributes(service: source)
        let unsharedStore = KeychainItemStore(attributes: unsharedAttributes, logger: logger)

        try KeychainItemMigrator(
            source: sharedAttributes,
            destination: unsharedAttributes,
            sourceStore: KeychainItemStore(attributes: sharedAttributes, logger: logger),
            destinationStore: unsharedStore,
            logger: logger
        ).migrate()

        let moved = RealKeychain.rows(service: source)
        let left = RealKeychain.rows(service: destination)
        RealKeychain.report(self, "shared->unshared: unshared service \(moved); shared service \(left)")
        XCTAssertEqual(moved.map(\.account), plugin.sorted(), "Q5: unshared service holds \(moved)")
        XCTAssertEqual(Set(moved.map(\.group)), [sharedGroup], "Q5: moved items changed group: \(moved)")
        XCTAssertEqual(left.map(\.account), [client], "Q5: shared service holds \(left)")
        for account in plugin {
            XCTAssertEqual(try unsharedStore.getData(account), Data(account.utf8), "Q5: unscoped read of \(account)")
        }
        XCTAssertEqual(try unsharedStore.allAccounts().sorted(), plugin.sorted(), "Q5: unscoped listing")
    }

    // MARK: - Q6

    /// KM-10. Q6: the whole-service `SecItemUpdate` used before the scoped wipe, when one of several items
    /// collides.
    ///
    /// No scoped-wipe code depends on the answer; it decides whether per-account migration's partial state
    /// is new. The observed outcome is pinned.
    ///
    /// - Given: three plugin items in the source service, and one of them already in the destination
    ///   under the shared group
    /// - When:
    ///    - the old migrator's single update runs: `source.defaultGetQuery()` (no account) with
    ///      `moveAttributes(to:)`
    /// - Then (observed on iOS 26.5, pinned):
    ///    - the status is `errSecDuplicateItem`, yet the update is **not** all-or-nothing: the two
    ///      non-colliding items moved, and only the colliding one stayed in the source. So the old
    ///      migration also left a partial state, and the per-account skip is not new
    ///
    func testQ6OldWholeServiceUpdateWithOneCollision() throws {
        let accounts = ["amplify.us-east-1_Probe.alice.deviceMetadata", "amplify.us-east-1_Probe.session", "authConfiguration"]
        for account in accounts {
            XCTAssertEqual(RealKeychain.add("source", account: account, service: source), errSecSuccess)
        }
        XCTAssertEqual(RealKeychain.add("destination", account: accounts[1], service: destination, group: sharedGroup), errSecSuccess)
        let sourceAttributes = KeychainItemAttributes(service: source)
        let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: sharedGroup)
        let before = RealKeychain.rows(service: source) + RealKeychain.rows(service: destination)

        let status = SecItemUpdate(
            sourceAttributes.defaultGetQuery() as CFDictionary,
            sourceAttributes.moveAttributes(to: destinationAttributes) as CFDictionary
        )
        let inSource = RealKeychain.rows(service: source)
        let inDestination = RealKeychain.rows(service: destination)
        let observed = "\(RealKeychain.describe(status)); source \(inSource); destination \(inDestination)"
        RealKeychain.report(self, "old whole-service update with one collision: \(observed)")
        XCTAssertNotEqual(inSource + inDestination, before, "Q6: the update was all-or-nothing: \(observed)")
        XCTAssertEqual(status, errSecDuplicateItem, "Q6: \(observed)")
        XCTAssertEqual(inSource.map(\.account), [accounts[1]], "Q6: \(observed)")
        XCTAssertEqual(
            inDestination,
            [
                RealKeychain.Row(account: accounts[0], group: sharedGroup, value: "source"),
                RealKeychain.Row(account: accounts[1], group: sharedGroup, value: "destination"),
                RealKeychain.Row(account: accounts[2], group: sharedGroup, value: "source")
            ],
            "Q6: \(observed)"
        )
    }

    /// KM-11. Q6, with the Q2 fixture: what the old whole-service update did with an account stored in two
    /// groups, so the Q2 result can be compared with the behaviour before the scoped wipe.
    ///
    /// - Given: a plugin session in the source's default group, `authConfiguration` in both the default
    ///   and the shared group, and an empty destination
    /// - When:
    ///    - the old single update to (destination, shared group) runs
    /// - Then (observed on iOS 26.5, pinned):
    ///    - the status is `errSecDuplicateItem` and **nothing** moved, not even the session record,
    ///      which collides with nothing: a collision between two of the matched items themselves
    ///      aborts the whole update, unlike a collision with an item already in the destination (Q6)
    ///
    func testQ6OldWholeServiceUpdateWithAccountInTwoGroups() throws {
        XCTAssertEqual(RealKeychain.add("default", account: "amplify.us-east-1_Probe.session", service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("default", account: "authConfiguration", service: source), errSecSuccess)
        XCTAssertEqual(RealKeychain.add("shared", account: "authConfiguration", service: source, group: sharedGroup), errSecSuccess)
        let sourceAttributes = KeychainItemAttributes(service: source)
        let destinationAttributes = KeychainItemAttributes(service: destination, accessGroup: sharedGroup)

        let status = SecItemUpdate(
            sourceAttributes.defaultGetQuery() as CFDictionary,
            sourceAttributes.moveAttributes(to: destinationAttributes) as CFDictionary
        )
        let inSource = RealKeychain.rows(service: source)
        let inDestination = RealKeychain.rows(service: destination)
        let observed = "\(RealKeychain.describe(status)); source \(inSource); destination \(inDestination)"
        RealKeychain.report(self, "old whole-service update, account in two groups: \(observed)")
        XCTAssertEqual(status, errSecDuplicateItem, "Q6b: \(observed)")
        XCTAssertEqual(inDestination, [], "Q6b: \(observed)")
        XCTAssertEqual(
            inSource.map(\.account),
            ["amplify.us-east-1_Probe.session", "authConfiguration", "authConfiguration"],
            "Q6b: \(observed)"
        )
    }
}
