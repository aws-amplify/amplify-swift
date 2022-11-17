//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSDataStoreCategoryPlugin

class RequestRetryablePolicyTests: XCTestCase {
    var retryPolicy: RequestRetryablePolicy!
    let defaultTimeout = DispatchTimeInterval.seconds(60)
    override func setUp() {
        super.setUp()
        retryPolicy = RequestRetryablePolicy()
    }

    func testNoErrorNoHttpURLResponse() {
        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssertFalse(retryAdvice.shouldRetry)
        XCTAssertEqual(retryAdvice.retryInterval, defaultTimeout)
    }

    func testNoErrorWithHttpURLResponseWithRetryAfterInHeader() {
        let headerFields = ["Retry-After": "42"]
        let url = URL(string: "http://www.amazon.com")!
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 429,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: headerFields)!

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: httpURLResponse,
                                                         attemptNumber: 1)
        XCTAssert(retryAdvice.shouldRetry)
        assertSeconds(retryAdvice.retryInterval, seconds: 42)
    }

    func testNoErrorWithHttpURLResponseWithoutRetryAfterInHeader_attempt1() {
        let url = URL(string: "http://www.amazon.com")!
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 429,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: nil)!

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: httpURLResponse,
                                                         attemptNumber: 1)
        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testNoErrorWithHttpURLResponseWithoutRetryAfterInHeader_attempt2() {
        let url = URL(string: "http://www.amazon.com")!
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 429,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: nil)!

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: httpURLResponse,
                                                         attemptNumber: 2)
        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 400, lessThan: 500)
    }

    func testNoErrorWithHttpURLResponseBeyondMaxWaitTime() {
        let url = URL(string: "http://www.amazon.com")!
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 429,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: nil)!

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: httpURLResponse,
                                                         attemptNumber: 12)
        XCTAssertFalse(retryAdvice.shouldRetry)
        XCTAssertEqual(retryAdvice.retryInterval, defaultTimeout)
    }

    func testNoErrorWithHttpURLResponseNotRetryable() {
        let url = URL(string: "http://www.amazon.com")!
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 204,
                                              httpVersion: "HTTP/1.1",
                                              headerFields: nil)!

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nil,
                                                         httpURLResponse: httpURLResponse,
                                                         attemptNumber: 1)
        XCTAssertFalse(retryAdvice.shouldRetry)
        XCTAssertEqual(retryAdvice.retryInterval, defaultTimeout)
    }

    func testNotConnectedToInternetErrorCode() {
        let retryableErrorCode = URLError.init(.notConnectedToInternet)
        let attemptNumber = 1

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: attemptNumber)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testNotConnectedToInternetErrorCode_attempt2() {
        let retryableErrorCode = URLError.init(.notConnectedToInternet)
        let attemptNumber = 2

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: attemptNumber)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 400, lessThan: 500)
    }

    func testNotConnectedToInternetErrorCode_attempt3() {
        let retryableErrorCode = URLError.init(.notConnectedToInternet)
        let attemptNumber = 3

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: attemptNumber)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 800, lessThan: 900)
    }

    func testDNSLookupFailedError() {
        let retryableErrorCode = URLError.init(.dnsLookupFailed)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testCannotConnectToHostError() {
        let retryableErrorCode = URLError.init(.cannotConnectToHost)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testCannotFindHostError() {
        let retryableErrorCode = URLError.init(.cannotFindHost)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testTimedOutError() {
        let retryableErrorCode = URLError.init(.timedOut)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testCannotParseResponseError() {
        let retryableErrorCode = URLError.init(.cannotParseResponse)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testNetworkConnectionLostError() {
        let retryableErrorCode = URLError.init(.networkConnectionLost)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 200, lessThan: 300)
    }

    func testHTTPTooManyRedirectsError() {
        let nonRetryableErrorCode = URLError.init(.httpTooManyRedirects)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: nonRetryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 1)

        XCTAssertFalse(retryAdvice.shouldRetry)
        XCTAssertEqual(retryAdvice.retryInterval, defaultTimeout)
    }

    func testMaxValueRetryDelay() {
        let retryableErrorCode = URLError.init(.timedOut)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 31)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 214_748_364_800, lessThan: 214_748_364_900)
    }

    func testBeyondMaxValueRetryDelay() {
        let retryableErrorCode = URLError.init(.timedOut)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 32)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 214_748_364_800, lessThan: 214_748_364_900)
    }

    func testOverflowCase() {
        let retryableErrorCode = URLError.init(.timedOut)

        let retryAdvice = retryPolicy.retryRequestAdvice(urlError: retryableErrorCode,
                                                         httpURLResponse: nil,
                                                         attemptNumber: 58)

        XCTAssert(retryAdvice.shouldRetry)
        assertMilliseconds(retryAdvice.retryInterval, greaterThan: 214_748_364_800, lessThan: 214_748_364_900)
    }

    func assertMilliseconds(_ retryInterval: DispatchTimeInterval?, greaterThan: Int, lessThan: Int) {
        guard let retryInterval = retryInterval else {
            XCTFail("retryInterval is nil")
            return
        }

        switch retryInterval {
        case .milliseconds(let milliseconds):
            XCTAssertGreaterThanOrEqual(milliseconds, greaterThan)
            XCTAssertLessThanOrEqual(milliseconds, lessThan)
        default:
            XCTFail("Expected milliseconds, but received \(retryInterval)")
        }
    }

    func assertSeconds(_ retryInterval: DispatchTimeInterval?, seconds expectedSeconds: Int) {
        guard let retryInterval = retryInterval else {
            XCTFail("retryInterval is nil")
            return
        }

        switch retryInterval {
        case .seconds(let seconds):
            XCTAssertEqual(seconds, expectedSeconds)
        default:
            XCTFail("Expected seconds, but received \(retryInterval)")
        }
    }
}
