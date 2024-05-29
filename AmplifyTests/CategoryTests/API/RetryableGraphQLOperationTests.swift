//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine
@testable import Amplify
@testable import AmplifyTestCommon

class RetryableGraphQLOperationTests: XCTestCase {
    let testApiName = "apiName"

    /// Given: a RetryableGraphQLOperation with 2 operations
    /// When: the first one fails with a .notAuthorized error, the next one succeed with response
    /// Then: return the success response
    func testShouldRetryOperationWithNotAuthorizedAuthError() async throws {
        let expectation1 = expectation(description: "Operation 1 throws signed out auth error")
        let operation1: () async throws -> GraphQLResponse<String> = {
            expectation1.fulfill()
            throw APIError.operationError("", "", AuthError.notAuthorized("", ""))
        }

        let expectation2 = expectation(description: "Operation 2 successfully finished")
        let operation2: () async throws -> GraphQLResponse<String> = {
            expectation2.fulfill()
            return .success("operation 2")
        }

        let operationStream = AsyncStream { continuation in
            continuation.yield(operation1)
            continuation.yield(operation2)
            continuation.finish()
        }
        let result = await RetryableGraphQLOperation(requestStream: operationStream).run()
        if case .success(.success(let string)) = result {
            XCTAssertEqual(string, "operation 2")
        } else {
            XCTFail("Wrong result")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 1)
    }

    /// Given: a RetryableGraphQLOperation with 2 operations
    /// When: the first one fails with a .notAuthorized error, the next one succeed with response
    /// Then: return the success response
    func testShouldNotRetryOperationWithUnknownError() async throws {
        let expectation1 = expectation(description: "Operation 1 throws signed out auth error")
        let operation1: () async throws -> GraphQLResponse<String> = {
            expectation1.fulfill()
            throw APIError.unknown("~Unknown~", "")
        }

        let expectation2 = expectation(description: "Operation 2 successfully finished")
        expectation2.isInverted = true
        let operation2: () async throws -> GraphQLResponse<String> = {
            expectation2.fulfill()
            return .success("operation 2")
        }

        let operationStream = AsyncStream { continuation in
            continuation.yield(operation1)
            continuation.yield(operation2)
            continuation.finish()
        }
        let result = await RetryableGraphQLOperation(requestStream: operationStream).run()
        if case .failure(.unknown(let description, _, _)) = result {
            XCTAssertEqual(description, "~Unknown~")
        } else {
            XCTFail("Wrong result")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 0.3)
    }
}
