//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Security
import XCTest
import AmplifyKeychainTestCommon
@testable import InternalAmplifyKeychain

/// `setIfUnchanged` is a protocol extension, so the real store and the fake run the same logic; only
/// the underlying add, replace and read differ. These tests exercise it over the fake.
final class SetIfUnchangedTests: XCTestCase {

    private let service = "service"
    private let key = "record"
    private let old = Data("old".utf8)
    private let new = Data("new".utf8)
    private let other = Data("other".utf8)

    /// The ordinary commit: nothing moved since the caller read, so the write lands.
    ///
    /// - Given: a stored value equal to `expecting`
    /// - When: `setIfUnchanged` is called
    /// - Then:
    ///    - it returns `true`, the new value is stored, and exactly one write to that key is recorded
    func testWritesWhenStoredValueMatches() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try store.set(old, key: key)
        keychain.resetMutations()

        XCTAssertTrue(try store.setIfUnchanged(new, key: key, expecting: old))

        XCTAssertEqual(keychain.value(service: service, account: key), new)
        XCTAssertEqual(keychain.mutations, [.write(service: service, account: key, value: new)])
    }

    /// Another writer moved the record since the caller read it. The caller's write is discarded and
    /// the newer value survives.
    ///
    /// - Given: a stored value different from `expecting`
    /// - When: `setIfUnchanged` is called
    /// - Then:
    ///    - it returns `false`, the stored bytes are untouched, and nothing is written
    func testRefusesWhenStoredValueChanged() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try store.set(other, key: key)
        keychain.resetMutations()

        XCTAssertFalse(try store.setIfUnchanged(new, key: key, expecting: old))

        XCTAssertEqual(keychain.value(service: service, account: key), other)
        XCTAssertEqual(keychain.mutations, [])
    }

    /// Expecting absence, with nothing stored, adds the item.
    ///
    /// - Given: no item under the key
    /// - When: `setIfUnchanged` is called expecting `nil`
    /// - Then:
    ///    - it returns `true` and the value is stored
    func testExpectAbsentWritesWhenAbsent() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)

        XCTAssertTrue(try store.setIfUnchanged(new, key: key, expecting: nil))

        XCTAssertEqual(keychain.value(service: service, account: key), new)
        XCTAssertEqual(keychain.writtenAccounts, [key])
    }

    /// Expecting absence, with an item already stored, writes nothing.
    ///
    /// - Given: an item under the key
    /// - When: `setIfUnchanged` is called expecting `nil`
    /// - Then:
    ///    - it returns `false` and the existing value is untouched
    func testExpectAbsentRefusesWhenPresent() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try store.set(other, key: key)
        keychain.resetMutations()

        XCTAssertFalse(try store.setIfUnchanged(new, key: key, expecting: nil))

        XCTAssertEqual(keychain.value(service: service, account: key), other)
        XCTAssertEqual(keychain.mutations, [])
    }

    /// The record was deleted since the caller read it (for example, a sign-out). The write must not
    /// resurrect it.
    ///
    /// - Given: no item under the key
    /// - When: `setIfUnchanged` is called expecting a value
    /// - Then:
    ///    - it returns `false` and nothing is written
    func testExpectValueRefusesWhenAbsent() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)

        XCTAssertFalse(try store.setIfUnchanged(new, key: key, expecting: old))

        XCTAssertNil(keychain.value(service: service, account: key))
        XCTAssertEqual(keychain.mutations, [])
    }

    /// A failed re-read is an error, never a silent write or a silent refusal.
    ///
    /// - Given: reads fail as if the device were locked
    /// - When: `setIfUnchanged` is called
    /// - Then:
    ///    - it throws the locked status and nothing is written
    func testReadFailurePropagates() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        try store.set(old, key: key)
        keychain.resetMutations()
        keychain.failing(.read, with: errSecInteractionNotAllowed)

        XCTAssertThrowsError(try store.setIfUnchanged(new, key: key, expecting: old)) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
        XCTAssertEqual(keychain.value(service: service, account: key), old)
        XCTAssertEqual(keychain.mutations, [])
    }

    /// On the expect-absent path the add itself refuses a duplicate, so another writer that adds the
    /// item between the re-read and the write still wins.
    ///
    /// - Given: no item, and another writer that adds one right after the re-read
    /// - When: `setIfUnchanged` is called expecting `nil`
    /// - Then:
    ///    - it returns `false` and the other writer's value survives
    func testConcurrentAddBetweenReadAndWriteWins() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        let rival = keychain.store(service: service)
        let other = other
        keychain.afterRead { _, account in
            keychain.afterRead(nil)
            _ = try? rival.addIfAbsent(other, key: account)
        }

        XCTAssertFalse(try store.setIfUnchanged(new, key: key, expecting: nil))

        XCTAssertEqual(keychain.value(service: service, account: key), other)
    }

    /// Documents the limit the doc comment states: the guard is not atomic. A replace that lands
    /// between the re-read and the write is overwritten. This test pins that behaviour so nobody
    /// mistakes the guard for a lock.
    ///
    /// - Given: a stored value equal to `expecting`, and another writer that replaces it right after
    ///   the re-read
    /// - When: `setIfUnchanged` is called
    /// - Then:
    ///    - it returns `true` and the caller's value overwrites the other writer's
    func testConcurrentReplaceBetweenReadAndWriteIsNotDetected() throws {
        let keychain = InMemoryKeychain()
        let store = keychain.store(service: service)
        let rival = keychain.store(service: service)
        try store.set(old, key: key)
        let other = other
        keychain.afterRead { _, account in
            keychain.afterRead(nil)
            _ = try? rival.replaceIfPresent(other, key: account)
        }

        XCTAssertTrue(try store.setIfUnchanged(new, key: key, expecting: old))

        XCTAssertEqual(keychain.value(service: service, account: key), new)
        XCTAssertEqual(keychain.writtenAccounts, [key, key, key])
    }
}
