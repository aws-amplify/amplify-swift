//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache

/// `Options.cacheIdentifier`: a cache of its own per identifier, within one region.
class AmplifyFirehoseClientCacheIdentifierTests: XCTestCase {

    /// A region of this test's own, so the region's default cache file is this test's too, not one another test
    /// (or the machine's user) left behind.
    private let region = "us-unit-\(UInt32.random(in: 1_000 ... UInt32.max))"

    /// Where the cache file for `cacheIdentifier` (or, with none, the region's default file) is, removed when the
    /// test ends.
    private func cacheFile(cacheIdentifier: String? = nil) throws -> URL {
        let fileName = try SQLiteRecordStorage.fileName(dbPrefix: "firehose_records", identifier: region, cacheIdentifier: cacheIdentifier)
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let file = directory.appendingPathComponent(fileName)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: file)
        }
        return file
    }

    /// A client over the cache named `cacheIdentifier`, whose file is removed when the test ends.
    private func makeClient(cacheIdentifier: String) throws -> AmplifyFirehoseClient {
        _ = try cacheFile(cacheIdentifier: cacheIdentifier)
        return try AmplifyFirehoseClient(
            region: region,
            credentialsProvider: MockFirehoseCredentialsProvider(),
            options: .init(flushStrategy: .none, cacheIdentifier: cacheIdentifier)
        )
    }

    /// Two sessions' clients in one region keep their records apart.
    ///
    /// - Given: in one region, two clients with different cache identifiers, and a third with the first's
    /// - When: the first records one record, then the second and the third clear their caches
    /// - Then:
    ///    - the second clears nothing: its cache is its own
    ///    - the third clears the record: the same identifier is the same cache
    func testClientsWithDifferentCacheIdentifiersKeepSeparateCaches() async throws {
        let work = UUID().uuidString
        let home = UUID().uuidString
        let first = try makeClient(cacheIdentifier: work)
        let second = try makeClient(cacheIdentifier: home)
        let third = try makeClient(cacheIdentifier: work)

        try await first.record(data: Data("record".utf8), streamName: "stream")
        let clearedBySecond = try await second.clearCache()
        let clearedByThird = try await third.clearCache()

        XCTAssertEqual(clearedBySecond.recordsCleared, 0)
        XCTAssertEqual(clearedByThird.recordsCleared, 1)
    }

    /// Existing caches are kept: a client with no cache identifier still uses the region's file.
    ///
    /// - Given: a region with no cache file yet; in it, a client with no cache identifier and one with an identifier
    /// - When: the first records one record, then the second clears its cache, then the first clears its own
    /// - Then:
    ///    - the region's file, `firehose_records_<region>.db`, did not exist before the first client and exists after
    ///    - the named client clears nothing, and the unnamed one clears its record
    func testAClientWithoutACacheIdentifierUsesTheRegionsCache() async throws {
        let regionsFile = try cacheFile()
        XCTAssertEqual(regionsFile.lastPathComponent, "firehose_records_\(region).db")
        XCTAssertFalse(FileManager.default.fileExists(atPath: regionsFile.path))
        let shared = try AmplifyFirehoseClient(region: region, credentialsProvider: MockFirehoseCredentialsProvider(), options: .init(flushStrategy: .none))
        let named = try makeClient(cacheIdentifier: UUID().uuidString)

        try await shared.record(data: Data("record".utf8), streamName: "stream")
        let clearedByNamed = try await named.clearCache()
        let clearedByShared = try await shared.clearCache()

        XCTAssertTrue(FileManager.default.fileExists(atPath: regionsFile.path))
        XCTAssertEqual(clearedByNamed.recordsCleared, 0)
        XCTAssertEqual(clearedByShared.recordsCleared, 1)
    }

    /// - Given: options with an empty cache identifier
    /// - When: a client is created
    /// - Then:
    ///    - it throws `FirehoseError.validation`, the client's own error type
    func testAnEmptyCacheIdentifierThrowsValidation() {
        let options = AmplifyFirehoseClient.Options(flushStrategy: .none, cacheIdentifier: "")
        XCTAssertThrowsError(try AmplifyFirehoseClient(region: region, credentialsProvider: MockFirehoseCredentialsProvider(), options: options)) { error in
            guard case FirehoseError.validation = error else {
                return XCTFail("expected FirehoseError.validation, got \(error)")
            }
        }
    }
}
