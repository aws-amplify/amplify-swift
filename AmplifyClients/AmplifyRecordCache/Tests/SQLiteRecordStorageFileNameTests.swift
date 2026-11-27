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

    /// Identifiers that compare equal as `String`s name one cache, in whichever Unicode form they were typed.
    ///
    /// - Given: "café" with a precomposed é (NFC) and with an e followed by a combining accent (NFD), and a Korean
    ///   syllable written whole and as a syllable followed by its final consonant: each pair is equal as `String`s
    ///   and differs in its UTF-8 bytes
    /// - When: their file names are built
    /// - Then:
    ///    - each pair names one file, for "café" the one of the decomposed form's SHA-256
    func testACacheIdentifierNamesOneFileInEitherNormalizationForm() throws {
        let composed = "caf\u{E9}"
        let decomposed = "cafe\u{301}"
        XCTAssertEqual(composed, decomposed)
        XCTAssertNotEqual(Array(composed.utf8), Array(decomposed.utf8))

        // SHA-256 of the decomposed form's UTF-8, from `printf 'cafe\xcc\x81' | shasum -a 256`.
        let expected = "kinesis_records_us-east-1_81ef060bcd98adc7824eb5c1ada83c32491b16018e11e79f00ab9d09e04b015a.db"
        XCTAssertEqual(try fileName(composed), expected)
        XCTAssertEqual(try fileName(decomposed), expected)

        // Foundation's composed mapping leaves this pair apart, which is why the decomposed form is hashed.
        let syllable = "\u{AC01}"
        let syllableAndFinal = "\u{AC00}\u{11A8}"
        XCTAssertEqual(syllable, syllableAndFinal)
        XCTAssertEqual(try fileName(syllable), try fileName(syllableAndFinal))
    }

    /// Only canonical equivalence joins two identifiers: compatibility forms stay apart, as `==` keeps them.
    ///
    /// - Given: the ligature "ﬁ" and the letters "fi", which are not equal as `String`s
    /// - When: their file names are built
    /// - Then:
    ///    - they name different files
    func testIdentifiersThatDifferOnlyInCompatibilityFormNameDifferentFiles() throws {
        XCTAssertNotEqual("\u{FB01}", "fi")
        XCTAssertNotEqual(try fileName("\u{FB01}"), try fileName("fi"))
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
