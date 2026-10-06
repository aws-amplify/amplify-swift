//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The commit guard's token, `RecordVersion`, over a named session's record: a write commits only when it
/// expects exactly the version stored, and never otherwise.
final class RecordVersionTests: XCTestCase {

    private var keychain: TestKeychain!
    private var store: SessionRecordStore!
    private var work: SessionID!
    private var workAccount: String { store.sessionAccount(for: work) }

    override func setUpWithError() throws {
        keychain = TestKeychain()
        store = keychain.recordStore(for: StorageFixtures.namespace)
        work = try SessionID.named("work")
    }

    /// The version a read of the record returns; `nil` if it is not a readable record.
    private func storedVersion() throws -> RecordVersion? {
        guard case .record(let stored) = try store.read(work) else {
            return nil
        }
        return stored.version
    }

    /// - Given: a named record at generation 3
    /// - When: a write expects `.generation(2)`
    /// - Then:
    ///    - it is `.discarded`, and the stored bytes are unchanged
    func testAStaleGenerationIsDiscarded() throws {
        try store.write(StorageFixtures.signedIn(credentials: "tokens-v1"), for: work, expecting: nil)
        try store.write(StorageFixtures.signedIn(credentials: "tokens-v2"), for: work, expecting: .generation(1))
        try store.write(StorageFixtures.signedIn(credentials: "tokens-v3"), for: work, expecting: .generation(2))
        XCTAssertEqual(try storedVersion(), .generation(3))
        let before = keychain.value(workAccount)

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "stale"), for: work, expecting: .generation(2))

        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(keychain.value(workAccount), before)
    }

    /// - Given: a stored record
    /// - When: a write expects `nil`, "I read no record"
    /// - Then:
    ///    - it is `.discarded`, and the stored bytes are unchanged
    func testExpectingNothingOverAnExistingRecordIsDiscarded() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let before = keychain.value(workAccount)

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "other"), for: work, expecting: nil)

        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(keychain.value(workAccount), before)
    }

    /// - Given: a named record at the largest generation
    /// - When: a write expects exactly that generation
    /// - Then:
    ///    - it is `.discarded` rather than wrapping the generation around, and nothing is written
    func testGenerationOverflowIsDiscarded() throws {
        let envelope = SessionRecordEnvelope(generation: .max, lastWriteTimestamp: TestClock.start, record: StorageFixtures.signedIn())
        keychain.put(try envelope.encoded(), workAccount)
        XCTAssertEqual(try storedVersion(), .generation(.max))
        keychain.resetLogs()

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "next"), for: work, expecting: .generation(.max))

        XCTAssertEqual(outcome, .discarded)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A version of one form never matches a record stored in the other.
    ///
    /// - Given: a named record
    /// - When: a write expects `.storedBytes` of exactly the bytes stored
    /// - Then:
    ///    - it is `.discarded`: a named record is guarded on its generation only, and the stored bytes are unchanged
    func testStoredBytesNeverMatchANamedRecord() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let before = try XCTUnwrap(keychain.value(workAccount))

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "other"), for: work, expecting: .storedBytes(before))

        XCTAssertEqual(outcome, .discarded)
        XCTAssertEqual(keychain.value(workAccount), before)
    }

    /// - Given: no record
    /// - When: a write expects `.storedBytes`
    /// - Then:
    ///    - it is `.discarded`, and nothing is written: only `nil` expects an absent record
    func testStoredBytesOverAnAbsentRecordIsDiscarded() throws {
        let outcome = try store.write(StorageFixtures.signedIn(), for: work, expecting: .storedBytes(Data("bytes".utf8)))

        XCTAssertEqual(outcome, .discarded)
        XCTAssertNil(keychain.value(workAccount))
        XCTAssertFalse(keychain.hasMutations)
    }

    /// - Given: a named record, read
    /// - When: a write expects the version the read returned
    /// - Then:
    ///    - it commits one generation on, and the next read returns that generation
    func testTheVersionAReadReturnsCommits() throws {
        try store.write(StorageFixtures.signedIn(), for: work, expecting: nil)
        let read = try storedVersion()
        XCTAssertEqual(read, .generation(1))

        let outcome = try store.write(StorageFixtures.signedIn(credentials: "tokens-v2"), for: work, expecting: read)

        XCTAssertTrue(outcome.didCommit)
        XCTAssertEqual(try storedVersion(), .generation(2))
    }
}
