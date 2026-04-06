//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyKinesisClient

class KinesisErrorConversionTests: XCTestCase {

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
