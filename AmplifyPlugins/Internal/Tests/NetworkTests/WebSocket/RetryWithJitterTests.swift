//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable @_spi(WebSocket) import AWSPluginsCore

class RetryWithJitterTests: XCTestCase {
    struct TestError: Error {
        let message: String
    }

    func testNext_returnDistinctValues() async {
        let retryWithJitter = RetryWithJitter()
        var values = Set<UInt>()
        for _ in 0..<20 {
            values.insert(await retryWithJitter.next())
        }
        XCTAssert(values.count > 10)
    }

    func testNext_doNotBreachMaxCap() async {
        let max: UInt = 100_000
        let retryWithJitter = RetryWithJitter(max: max)
        var values = Set<UInt>()
        for _ in 0..<50 {
            values.insert(await retryWithJitter.next())
        }
        XCTAssert(values.allSatisfy { $0 < max})
    }

    func testExecute_operationFailed_retryToMaxRetryCount() async {
        let maxRetryCount = 3
        let retryAttempts = expectation(description: "Total retry attempts")
        retryAttempts.expectedFulfillmentCount = maxRetryCount
        let failedWithExceedMaxRetryCountError =
            expectation(description: "Execute should be failed with exceedMaxRetryCount error")
        do {
            try await RetryWithJitter.execute(maxRetryCount: UInt(maxRetryCount)) {
                retryAttempts.fulfill()
                throw TestError(message: "Failed operation")
            }
        } catch {
            XCTAssert(error is RetryWithJitter.Error)
            if case .maxRetryExceeded(let errors) = (error as! RetryWithJitter.Error) {
                XCTAssertEqual(errors.count, maxRetryCount)
                XCTAssert(errors.reduce(true) {
                    $0 && (($1 as? TestError).map { $0.message.contains("Failed operation") } == true)
                } )
                failedWithExceedMaxRetryCountError.fulfill()
            }
        }
        await fulfillment(of: [retryAttempts, failedWithExceedMaxRetryCountError], timeout: 5)
    }

    func testExecute_operationSucceeded_noRetryObserved() async {
        let maxRetryCount = 3
        let retryAttempts = expectation(description: "Total retry attempts")
        retryAttempts.isInverted = true
        let succeedExpectation =
            expectation(description: "Execute should be succeed")
        do {
            try await RetryWithJitter.execute(maxRetryCount: UInt(maxRetryCount)) {
                succeedExpectation.fulfill()
            }
        } catch {
            XCTFail("No error expected")
        }
        await fulfillment(of: [retryAttempts, succeedExpectation], timeout: 1)
    }
}
