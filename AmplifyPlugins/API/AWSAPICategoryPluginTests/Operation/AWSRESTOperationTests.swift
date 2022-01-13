//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class AWSRESTOperationTests: OperationTestBase {

    func testRESTOperationSuccess() {
        XCTFail("Not yet implemented.")
    }

    func testRESTOperationValidationError() {
        XCTFail("Not yet implemented.")
    }

    func testRESTOperationEndpointConfigurationError() {
        XCTFail("Not yet implemented.")
    }

    func testRESTOperationConstructURLFailure() {
        XCTFail("Not yet implemented.")
    }

    func testRESTOperationInterceptorError() {
        XCTFail("Not yet implemented.")
    }

    func testGetReturnsOperation() throws {
        try setUpPlugin(endpointType: .rest)

        // Use this as a semaphore to ensure the task is cleaned up before proceeding to the next test
        let listenerWasInvoked = expectation(description: "Listener was invoked")
        let request = RESTRequest(apiName: "Valid", path: "/path")
        let operation = apiPlugin.get(request: request) { _ in listenerWasInvoked.fulfill() }

        XCTAssertNotNil(operation)

        guard operation is AWSRESTOperation else {
            XCTFail("operation could not be cast as AWSAPIGetOperation")
            return
        }

        XCTAssertNotNil(operation.request)

        waitForExpectations(timeout: 1.00)
    }

    func testGetFailsWithBadAPIName() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleResponse(sending: sentData, for: .rest)

        let receivedSuccess = expectation(description: "Received success")
        receivedSuccess.isInverted = true
        let receivedFailure = expectation(description: "Received failed")

        let request = RESTRequest(apiName: "INVALID_API_NAME", path: "/path")
        _ = apiPlugin.get(request: request) { event in
            switch event {
            case .success:
                receivedSuccess.fulfill()
            case .failure:
                receivedFailure.fulfill()
            }
        }

        waitForExpectations(timeout: 1.00)
    }

    /// - Given: A configured plugin
    /// - When: I invoke `APICategory.get(apiName:path:listener:)`
    /// - Then: The listener is invoked with the successful value
    func testGetReturnsValue() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleResponse(sending: sentData, for: .rest)

        let callbackInvoked = expectation(description: "Callback was invoked")
        let request = RESTRequest(apiName: "Valid", path: "/path")
        _ = apiPlugin.get(request: request) { event in
            switch event {
            case .success(let data):
                XCTAssertEqual(data, sentData)
            case .failure(let error):
                XCTFail("Unexpected failure: \(error)")
            }
            callbackInvoked.fulfill()
        }

        wait(for: [callbackInvoked], timeout: 1.0)
    }

}
