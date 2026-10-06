//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyKinesisClient
@testable import AmplifyRecordCache

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class KinesisErrorConversionTests: XCTestCase, @unchecked Sendable {

    /// - Given: a `KinesisError.cache` error
    /// - When: it is converted with `KinesisError.from(_:)`
    /// - Then:
    ///    - the result is the same `.cache` case, with the same description and recovery suggestion
    func testFromShouldPassThroughKinesisErrorUnchanged() {
        let original = KinesisError.cache("msg", "suggestion")
        let result = KinesisError.from(original)

        guard case .cache(let desc, let suggestion, _) = result else {
            XCTFail("Expected .cache, got \(result)")
            return
        }
        XCTAssertEqual(desc, "msg")
        XCTAssertEqual(suggestion, "suggestion")
    }

    /// - Given: a `RecordCacheError.validation` error
    /// - When: it is converted with `KinesisError.from(_:)`
    /// - Then:
    ///    - the result is `KinesisError.validation`, with the same description and recovery suggestion
    func testFromShouldConvertRecordCacheValidationErrorToValidation() {
        let cause = RecordCacheError.validation("bad input", "fix it")
        let result = KinesisError.from(cause)

        guard case .validation(let desc, let suggestion, _) = result else {
            XCTFail("Expected .validation, got \(result)")
            return
        }
        XCTAssertEqual(desc, "bad input")
        XCTAssertEqual(suggestion, "fix it")
    }

    /// - Given: a `RecordCacheError.database` error
    /// - When: it is converted with `KinesisError.from(_:)`
    /// - Then:
    ///    - the result is `KinesisError.cache`, with the same description and recovery suggestion
    func testFromShouldConvertRecordCacheDatabaseErrorToCache() {
        let cause = RecordCacheError.database("db error", "retry")
        let result = KinesisError.from(cause)

        guard case .cache(let desc, let suggestion, _) = result else {
            XCTFail("Expected .cache, got \(result)")
            return
        }
        XCTAssertEqual(desc, "db error")
        XCTAssertEqual(suggestion, "retry")
    }

    /// - Given: a `RecordCacheError.limitExceeded` error
    /// - When: it is converted with `KinesisError.from(_:)`
    /// - Then:
    ///    - the result is `KinesisError.cacheLimitExceeded`, with the same description and recovery suggestion
    func testFromShouldConvertRecordCacheLimitExceededErrorToCacheLimitExceeded() {
        let cause = RecordCacheError.limitExceeded("cache full", "flush first")
        let result = KinesisError.from(cause)

        guard case .cacheLimitExceeded(let desc, let suggestion, _) = result else {
            XCTFail("Expected .cacheLimitExceeded, got \(result)")
            return
        }
        XCTAssertEqual(desc, "cache full")
        XCTAssertEqual(suggestion, "flush first")
    }

    /// - Given: an `NSError`, which is neither a `KinesisError` nor a `RecordCacheError`
    /// - When: it is converted with `KinesisError.from(_:)`
    /// - Then:
    ///    - the result is `KinesisError.unknown` with the generic description, and it keeps the original error
    ///      as its underlying error
    func testFromShouldConvertUnknownErrorToUnknown() {
        let cause = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "something unexpected"])
        let result = KinesisError.from(cause)

        guard case .unknown(let desc, _, let underlyingError) = result else {
            XCTFail("Expected .unknown, got \(result)")
            return
        }
        XCTAssertEqual(desc, "An unknown error occurred")
        XCTAssertNotNil(underlyingError)
    }
}
