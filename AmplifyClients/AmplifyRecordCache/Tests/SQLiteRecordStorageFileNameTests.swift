//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyRecordCache

/// The cache's file name: the region's shared file by default, and a file of its own per cache identifier.
final class SQLiteRecordStorageFileNameTests: XCTestCase {

    private func fileName(_ cacheIdentifier: String?) throws -> String {
        try SQLiteRecordStorage.fileName(dbPrefix: "kinesis_records", identifier: "us-east-1", cacheIdentifier: cacheIdentifier)
    }

    /// Existing caches are kept: with no cache identifier the file is the one a release before the option used.
    ///
    /// - Given: a prefix and a region, and no cache identifier
    /// - When: the file name is built
    /// - Then:
    ///    - it is `<prefix>_<region>.db`
    func testNoCacheIdentifierKeepsTheRegionsFile() throws {
        XCTAssertEqual(try fileName(nil), "kinesis_records_us-east-1.db")
    }

    /// - Given: cache identifiers that differ only in case, one with path separators, and one given twice
    /// - When: their file names are built
    /// - Then:
    ///    - each is the region's name plus the identifier's SHA-256 in lowercase hex, and holds nothing of the
    ///      identifier itself
    ///    - identifiers that differ only in case get different names, even compared without case
    ///    - the same identifier gets the same name
    func testACacheIdentifierNamesAFileOfItsOwn() throws {
        let lower = try fileName("work")
        let upper = try fileName("WORK")
        let path = try fileName("../../etc/Work")

        // SHA-256("work"), from `printf work | shasum -a 256`.
        XCTAssertEqual(lower, "kinesis_records_us-east-1_00e13ed7af55b27622f1d6eab5bec0147e68efe28dc2b12461117afa1a5ed40e.db")
        XCTAssertNotEqual(lower.lowercased(), upper.lowercased())
        XCTAssertEqual(lower, try fileName("work"))
        for name in [lower, upper, path] {
            let hash = name.dropFirst("kinesis_records_us-east-1_".count).dropLast(".db".count)
            XCTAssertTrue(name.hasPrefix("kinesis_records_us-east-1_") && name.hasSuffix(".db"), name)
            XCTAssertTrue(hash.allSatisfy { "0123456789abcdef".contains($0) }, name)
            XCTAssertFalse(name.contains("/"), name)
        }
    }

    /// - Given: an empty cache identifier
    /// - When: the file name is built
    /// - Then:
    ///    - it throws `RecordCacheError.validation`
    func testAnEmptyCacheIdentifierIsRefused() {
        XCTAssertThrowsError(try fileName("")) { error in
            guard case RecordCacheError.validation = error else {
                return XCTFail("expected .validation, got \(error)")
            }
        }
    }
}
