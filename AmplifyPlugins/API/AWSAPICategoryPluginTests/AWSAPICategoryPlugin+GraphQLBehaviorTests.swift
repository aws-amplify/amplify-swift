//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin

class AWSAPICategoryPluginGraphQLBehaviorTests: AWSAPICategoryPluginTestBase {

    // MARK: Query API Tests

    func testQuery() {
        let operationFinished = expectation(description: "Operation should finish")
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)
        let operation = apiPlugin.query(request: request) { _ in
            operationFinished.fulfill()
        }

        XCTAssertNotNil(operation)

        guard let queryOperation = operation as? AWSGraphQLOperation<JSONValue> else {
            XCTFail("operation could not be cast to AWSGraphQLOperation")
            return
        }

        let operationRequest = queryOperation.request
        XCTAssertNotNil(operationRequest)
        XCTAssertEqual(operationRequest.apiName, apiName)
        XCTAssertEqual(operationRequest.document, testDocument)
        XCTAssertEqual(operationRequest.operationType, GraphQLOperationType.query)
        XCTAssertNotNil(operationRequest.options)
        XCTAssertNil(operationRequest.variables)
        waitForExpectations(timeout: 1)
    }

    // MARK: Mutate API Tests

    func testMutate() {
        let operationFinished = expectation(description: "Operation should finish")
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)
        let operation = apiPlugin.mutate(request: request) { _ in
            operationFinished.fulfill()
        }

        XCTAssertNotNil(operation)

        guard let mutateOperation = operation as? AWSGraphQLOperation<JSONValue> else {
            XCTFail("operation could not be cast to AWSGraphQLOperation")
            return
        }

        let operationRequest = mutateOperation.request
        XCTAssertNotNil(operationRequest)
        XCTAssertEqual(operationRequest.apiName, apiName)
        XCTAssertEqual(operationRequest.document, testDocument)
        XCTAssertEqual(operationRequest.operationType, GraphQLOperationType.mutation)
        XCTAssertNotNil(operationRequest.options)
        XCTAssertNil(operationRequest.variables)
        waitForExpectations(timeout: 1)
    }

    // MARK: Subscribe API Tests

    func testSubscribe() {
        let operationFinished = expectation(description: "Operation should finish")
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)
        let operation = apiPlugin.subscribe(request: request, valueListener: nil) { _ in
            operationFinished.fulfill()
        }

        XCTAssertNotNil(operation)

        guard let subscriptionOperation = operation as? AWSGraphQLSubscriptionOperation<JSONValue> else {
            XCTFail("operation could not be cast to AWSGraphQLOperation")
            return
        }

        let operationRequest = subscriptionOperation.request
        XCTAssertNotNil(operationRequest)
        XCTAssertEqual(operationRequest.apiName, apiName)
        XCTAssertEqual(operationRequest.document, testDocument)
        XCTAssertEqual(operationRequest.operationType, GraphQLOperationType.subscription)
        XCTAssertNotNil(operationRequest.options)
        XCTAssertNil(operationRequest.variables)
        waitForExpectations(timeout: 1)
    }
}
