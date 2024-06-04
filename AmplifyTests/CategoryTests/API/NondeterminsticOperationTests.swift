//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import Amplify

class NondeterminsticOperationTests: XCTestCase {
    enum TestError: Error {
        case error
    }
    /**
     Given: A nondeterminstic operation with all operation candidates would success
     When: execute the nondeterminstic operation
     Then: only first succeed operation will be executed
     */
    func test_withAllSucceedOperations_onlyFirstOneExecuted() async throws {
        let expectation1 = expectation(description: "opeartion 1 executed")
        let operation1: () async throws -> Void  =  {
            expectation1.fulfill()
        }
        let expectation2 = expectation(description: "opeartion 2 executed")
        expectation2.isInverted = true
        let operation2: () async throws -> Void  =  {
            expectation2.fulfill()
        }
        let expectation3 = expectation(description: "opeartion 3 executed")
        expectation3.isInverted = true
        let operation3: () async throws -> Void  =  {
            expectation3.fulfill()
        }

        let nondeterminsticOperation = NondeterminsticOperation(operations: AsyncStream { continuation in
            for operation in [operation1, operation2, operation3] {
                continuation.yield(operation)
            }
            continuation.finish()
        })

        try await nondeterminsticOperation.run()
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 0.2)
    }

    /**
     Given: A nondeterminstic operation with all operation candidates would fail
     When: execute the nondeterminstic operation
     Then: a totoal failure error is throwed and all operations are executed
     */
    func test_withAllFailedOperations_throwsTotoalFailureAndAllOperationsAreExecuted() async throws {
        let expectation1 = expectation(description: "opeartion 1 executed")
        let operation1: () async throws -> Void  =  {
            expectation1.fulfill()
            throw TestError.error
        }
        let expectation2 = expectation(description: "opeartion 2 executed")
        let operation2: () async throws -> Void  =  {
            expectation2.fulfill()
            throw TestError.error
        }
        let expectation3 = expectation(description: "opeartion 3 executed")
        let operation3: () async throws -> Void  =  {
            expectation3.fulfill()
            throw TestError.error
        }

        let nondeterminsticOperation = NondeterminsticOperation(operations: AsyncStream { continuation in
            for operation in [operation1, operation2, operation3] {
                continuation.yield(operation)
            }
            continuation.finish()
        })
        do {
            try await nondeterminsticOperation.run()
        } catch {
            XCTAssert(error is NondeterminsticOperationError)
            XCTAssertEqual(error as! NondeterminsticOperationError, NondeterminsticOperationError.totalFailure)
        }
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 0.2)
    }

    /**
     Given: A nondeterminstic operation with some operation candidates would succeed
     When: execute the nondeterminstic operation
     Then: all operations until the first success operation will be executed
     */
    func test_withSomeSuccessOperations_AllOperationsUntilSuccessOperationAreExecuted() async throws {
        let expectation1 = expectation(description: "opeartion 1 executed")
        let operation1: () async throws -> Void  =  {
            expectation1.fulfill()
            throw TestError.error
        }
        let expectation2 = expectation(description: "opeartion 2 executed")
        let operation2: () async throws -> Void  =  {
            expectation2.fulfill()
            throw TestError.error
        }
        let expectation3 = expectation(description: "opeartion 3 executed")
        let operation3: () async throws -> Void  =  {
            expectation3.fulfill()
        }
        let expectation4 = expectation(description: "opeartion  executed")
        expectation4.isInverted = true
        let operation4: () async throws -> Void  =  {
            expectation4.fulfill()
            throw TestError.error
        }

        let nondeterminsticOperation = NondeterminsticOperation(operations: AsyncStream { continuation in
            for operation in [operation1, operation2, operation3, operation4] {
                continuation.yield(operation)
            }
            continuation.finish()
        })
        do {
            try await nondeterminsticOperation.run()
        } catch {
            XCTAssert(error is NondeterminsticOperationError)
            XCTAssertEqual(error as! NondeterminsticOperationError, NondeterminsticOperationError.totalFailure)
        }
        await fulfillment(of: [expectation1, expectation2, expectation3, expectation4], timeout: 0.2)
    }
}
