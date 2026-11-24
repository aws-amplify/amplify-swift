//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache

/// A provider that cannot vend credentials, and says why.
private struct FailingCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    let error: CredentialsError

    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        throw error
    }
}

/// A flush whose credentials provider fails, through the real SDK client: the provider's `CredentialsError`
/// reaches `flush()` as `FirehoseError.credentials` before any request is sent, and its `disposition` decides what
/// happens to the cached records.
class AmplifyFirehoseClientCredentialsFailureTests: XCTestCase {

    /// A region of this test's own, so the region's shared cache file is this test's too, not one another test (or
    /// the machine's user) left behind.
    private let region = "us-unit-\(UInt32.random(in: 1_000 ... UInt32.max))"

    /// A client whose provider fails with `error`, over a cache of its own or, with no identifier, over the
    /// region's shared cache. Either file is removed when the test ends.
    private func makeClient(
        failingWith error: CredentialsError,
        cacheIdentifier: String?,
        maxRetries: Int = 5
    ) throws -> AmplifyFirehoseClient {
        let fileName = try SQLiteRecordStorage.fileName(dbPrefix: "firehose_records", identifier: region, cacheIdentifier: cacheIdentifier)
        addTeardownBlock {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
        }
        return try AmplifyFirehoseClient(
            region: region,
            credentialsProvider: FailingCredentialsProvider(error: error),
            options: .init(maxRetries: maxRetries, flushStrategy: .none, cacheIdentifier: cacheIdentifier)
        )
    }

    /// The `CredentialsError` under the `FirehoseError.credentials` a flush threw, or `nil` (and a failure).
    private func credentialsFailure(of client: AmplifyFirehoseClient, file: StaticString = #filePath, line: UInt = #line) async -> CredentialsError? {
        do {
            _ = try await client.flush()
            XCTFail("expected the flush to throw", file: file, line: line)
        } catch FirehoseError.credentials(let description, let suggestion, let cause) {
            let error = cause as? CredentialsError
            XCTAssertEqual(description, error?.errorDescription, file: file, line: line)
            XCTAssertEqual(suggestion, error?.recoverySuggestion, file: file, line: line)
            return error
        } catch {
            XCTFail("expected FirehoseError.credentials, got \(error)", file: file, line: line)
        }
        return nil
    }

    /// - Given: a client with a cache of its own, whose provider fails with `sessionExpired`, and one cached record
    /// - When: it flushes more often than `maxRetries`, then clears its cache
    /// - Then:
    ///    - every flush throws `FirehoseError.credentials` with the provider's texts and its error underneath
    ///    - the record is still cached: no retry was counted against it
    func testAnExpiredSessionKeepsTheRecords() async throws {
        let expired = CredentialsError.sessionExpired("expired", "sign in again")
        let client = try makeClient(failingWith: expired, cacheIdentifier: UUID().uuidString, maxRetries: 1)
        try await client.record(data: Data("record".utf8), streamName: "stream")

        for _ in 1 ... 3 {
            let thrown = await credentialsFailure(of: client)
            XCTAssertEqual(thrown?.disposition, .retryAfterReauthentication)
            XCTAssertEqual(thrown?.errorDescription, "expired")
        }
        let cleared = try await client.clearCache()

        XCTAssertEqual(cleared.recordsCleared, 1)
    }

    /// - Given: a client with a cache of its own, and one over the region's shared cache, whose providers fail with
    ///   `notSignedIn`; each has cached one record
    /// - When: each flushes, then clears its cache
    /// - Then:
    ///    - both flushes throw `FirehoseError.credentials` with the `notSignedIn` underneath
    ///    - the cache of the client's own was discarded: nothing is left to clear
    ///    - the region's shared cache was kept: its record is still there to clear
    func testASignedOutSessionDiscardsOnlyACacheOfItsOwn() async throws {
        let signedOut = CredentialsError.notSignedIn("signed out", "sign in first")
        let own = try makeClient(failingWith: signedOut, cacheIdentifier: UUID().uuidString)
        let shared = try makeClient(failingWith: signedOut, cacheIdentifier: nil)
        try await own.record(data: Data("record".utf8), streamName: "stream")
        try await shared.record(data: Data("record".utf8), streamName: "stream")

        let ownFailure = await credentialsFailure(of: own)
        let sharedFailure = await credentialsFailure(of: shared)
        let clearedOwn = try await own.clearCache()
        let clearedShared = try await shared.clearCache()

        XCTAssertEqual(ownFailure?.disposition, .discard)
        XCTAssertEqual(sharedFailure?.disposition, .discard)
        XCTAssertEqual(clearedOwn.recordsCleared, 0)
        XCTAssertEqual(clearedShared.recordsCleared, 1)
    }

    /// - Given: a `RecordCacheError.credentials` carrying a provider's error
    /// - When: it is converted with `FirehoseError.from(_:)`
    /// - Then:
    ///    - the result is `FirehoseError.credentials` with the same description, recovery suggestion and
    ///      underlying error, and its `AmplifyError` accessors return them
    func testFromConvertsACredentialsFailureToCredentials() {
        let cause = CredentialsError.notConfigured("no identity pool", "configure one")
        let result = FirehoseError.from(RecordCacheError.credentials("no identity pool", "configure one", cause))

        guard case .credentials(let description, let suggestion, let underlying) = result else {
            return XCTFail("expected .credentials, got \(result)")
        }
        XCTAssertEqual(description, "no identity pool")
        XCTAssertEqual(suggestion, "configure one")
        XCTAssertEqual((underlying as? CredentialsError)?.disposition, .failLoudly)
        XCTAssertEqual(result.errorDescription, "no identity pool")
        XCTAssertEqual(result.recoverySuggestion, "configure one")
        XCTAssertNotNil(result.underlyingError)
    }
}
