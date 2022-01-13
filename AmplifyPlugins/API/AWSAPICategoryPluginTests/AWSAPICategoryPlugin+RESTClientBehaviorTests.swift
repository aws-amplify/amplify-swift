//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSAPICategoryPluginRESTClientBehaviorTests: AWSAPICategoryPluginTestBase {

    // MARK: Get API tests

    func testGet() {
        let request = RESTRequest(apiName: apiName, path: testPath)
        let operation = apiPlugin.get(request: request, listener: nil)

        XCTAssertNotNil(operation)

        guard let getOperation = operation as? AWSRESTOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let operationRequest = getOperation.request
        XCTAssertNotNil(operationRequest)
        XCTAssertEqual(operationRequest.apiName, apiName)
        XCTAssertEqual(operationRequest.path, testPath)
        XCTAssertNil(operationRequest.body)
        XCTAssertEqual(operationRequest.operationType, RESTOperationType.get)
        XCTAssertNotNil(operationRequest.options)
        XCTAssertNotNil(operationRequest.path)
    }

    // MARK: Post API tests

    func testPost() {
        let request = RESTRequest(apiName: apiName, path: testPath, body: testBody)
        let operation = apiPlugin.post(request: request, listener: nil)

        XCTAssertNotNil(operation)

        guard let postOperation = operation as? AWSRESTOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let operationRequest = postOperation.request
        XCTAssertNotNil(operationRequest)
        XCTAssertEqual(operationRequest.apiName, apiName)
        XCTAssertEqual(operationRequest.path, testPath)
        XCTAssertEqual(operationRequest.body, testBody)
        XCTAssertEqual(operationRequest.operationType, RESTOperationType.post)
        XCTAssertNotNil(operationRequest.options)
        XCTAssertNotNil(operationRequest.path)
    }

    // MARK: Put API tests

    // MARK: Patch API tests

    // MARK: Delete API tests

    // MARK: HEAD API tests
}
