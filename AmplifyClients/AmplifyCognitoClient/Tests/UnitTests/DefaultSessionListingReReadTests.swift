//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// On macOS the keychain's `set` deletes the item and adds it again, so another writer's save of `.default`'s shared
/// record leaves a moment in which it is missing. With the re-read on, a listing and a sign-out read it once more
/// before they take it for absent, even when the account listing itself was taken in that moment.
final class DefaultSessionListingReReadTests: XCTestCase {

    private var keychain: TestKeychain!
    private let pools = StorageFixtures.pools
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }
    private let alice = FakePayload.signedIn("alice")

    override func setUp() {
        keychain = TestKeychain()
    }

    /// - Given: the re-read on, and another writer saving alice's login under `.default` in a delete-then-add whose gap
    ///   the account listing and the first read of the record fall into
    /// - When: the saved sessions are listed
    /// - Then:
    ///    - `.default` is listed as alice, signed in, after two reads of the record; with the re-read off, the record is
    ///      not read and `.default` is not listed
    func testAListingTakenInTheGapStillListsTheDefaultSession() throws {
        let store = keychain.recordStore(for: StorageFixtures.namespace, rereadsAbsentSharedRecord: true)
        landAfterFirstRead(alice.data)

        let sessions = try store.storedSessions()

        XCTAssertEqual(sessions.map(\.sessionId), [.default])
        XCTAssertEqual(sessions.first?.username, "alice")
        XCTAssertNotEqual(sessions.first?.kind, .signedOut)
        XCTAssertEqual(reads(of: pluginAccount), 2)

        try keychain.itemStore(service: SessionRecordStore.unsharedService).remove(pluginAccount)
        keychain.resetLogs()
        XCTAssertEqual(try keychain.recordStore(for: StorageFixtures.namespace).storedSessions(), [])
        XCTAssertEqual(reads(of: pluginAccount), 0)
    }

    /// - Given: the re-read on, and alice's login under `.default` landing in the gap of a delete-then-add, as above
    /// - When: the signed-in users are read, as a hosted-UI sign-in that must return a user of no other session does
    /// - Then:
    ///    - `.default` counts as alice, so that sign-in cannot return her
    func testTheSignedInUsersCountTheDefaultSessionInTheGap() throws {
        let store = keychain.recordStore(for: StorageFixtures.namespace, rereadsAbsentSharedRecord: true)
        landAfterFirstRead(alice.data)

        let userIds = try store.signedInUserIds(describe: { _ in nil })

        XCTAssertEqual(userIds, [.default: try XCTUnwrap(alice.userId)])
    }

    /// - Given: the re-read on, and `.default`'s shared record holding bytes this build cannot read, which another writer
    ///   replaces with alice's login in a delete-then-add right after the sign-out's first read
    /// - When: `.default` is signed out
    /// - Then:
    ///    - the sign-out finds alice on its re-read and is `.superseded`, leaving her login as it is, rather than
    ///      `.noRecord`, which would report a sign-out while she is signed in
    func testReplacingAnUnreadableRecordReReadsItBeforeAnsweringNoRecord() throws {
        let store = keychain.recordStore(for: StorageFixtures.namespace, rereadsAbsentSharedRecord: true)
        keychain.put(StorageFixtures.corruptRecord, pluginAccount)
        let other = keychain!
        let account = pluginAccount
        let counter = ReadOrdinal()
        let payload = alice.data
        other.afterEveryRead(of: account) {
            switch counter.next() {
            case 1:
                // The other writer's delete...
                try? other.itemStore(service: SessionRecordStore.unsharedService).remove(account)
            case 2:
                // ...and its add, after the sign-out's first read before replacing found nothing.
                other.put(payload, account)
            default:
                break
            }
        }

        XCTAssertEqual(try store.signOut(.default), .superseded)

        other.afterEveryRead(of: account, nil)
        XCTAssertEqual(other.value(account), payload)
    }

    // MARK: Helpers

    /// Makes `.default`'s shared record absent for the account listing and its first read, then present with `data`.
    private func landAfterFirstRead(_ data: Data) {
        let other = keychain!
        let account = pluginAccount
        other.onceAfterReading(account) { other.put(data, account) }
    }

    private func reads(of account: String) -> Int {
        keychain.readAccounts.count(where: { $0 == account })
    }
}

/// Counts calls, from 1, across threads.
private final class ReadOrdinal: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}
