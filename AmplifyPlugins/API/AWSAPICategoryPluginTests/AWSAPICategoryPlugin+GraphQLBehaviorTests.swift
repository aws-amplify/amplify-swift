//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPICategoryPlugin

class AWSAPICategoryPluginGraphQLBehaviorTests: AWSAPICategoryPluginTestBase {

    // MARK: Query API Tests

    func testQuery() {
        let operation = apiPlugin.query(apiName: apiName,
                                        document: testDocument,
                                        variables: testVariables,
                                        responseType: JSONValue.self,
                                        listener: nil)

        XCTAssertNotNil(operation)

        guard let queryOperation = operation as? AWSGraphQLOperation<JSONValue> else {
            XCTFail("operation could not be cast to AWSGraphQLOperation")
            return
        }

        let request = queryOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.document, testDocument)
        XCTAssertEqual(request.operationType, GraphQLOperationType.query)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.variables)
    }

    // MARK: Mutate API Tests

    func testMutate() {
        let operation = apiPlugin.mutate(apiName: apiName,
                                         document: testDocument,
                                         variables: testVariables,
                                         responseType: JSONValue.self,
                                         listener: nil)

        XCTAssertNotNil(operation)

        guard let mutateOperation = operation as? AWSGraphQLOperation<JSONValue> else {
            XCTFail("operation could not be cast to AWSGraphQLOperation")
            return
        }

        let request = mutateOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.document, testDocument)
        XCTAssertEqual(request.operationType, GraphQLOperationType.mutation)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.variables)
    }

    // MARK: Subscribe API Tests

    func testSubscribe() {
        XCTFail("Not yet implemented")
    }
}
