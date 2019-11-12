//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin
@testable import AmplifyTestCommon

class AWSAPICategoryPluginRESTClientBehaviorTests: AWSAPICategoryPluginTestBase {

    // MARK: Get API tests

    func testGet() {
        let operation = apiPlugin.get(apiName: apiName, path: testPath, listener: nil)

        XCTAssertNotNil(operation)

        guard let getOperation = operation as? AWSRESTOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let request = getOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.path, testPath)
        XCTAssertNil(request.body)
        XCTAssertEqual(request.operationType, RESTOperationType.get)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.path)
    }

    // MARK: Post API tests

    func testPost() {
        let operation = apiPlugin.post(apiName: apiName, path: testPath, body: testBody, listener: nil)

        XCTAssertNotNil(operation)

        guard let postOperation = operation as? AWSRESTOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let request = postOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.path, testPath)
        XCTAssertEqual(request.body, testBody)
        XCTAssertEqual(request.operationType, RESTOperationType.post)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.path)
    }

    // MARK: Put API tests

    // MARK: Patch API tests

    // MARK: Delete API tests
}
