//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StorageGetOperationTests: XCTestCase {
    var mockAmplifyConfig: BasicAmplifyConfiguration!

    override func setUp() {
        Amplify.reset()

        let hubConfig = BasicCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )

        mockAmplifyConfig = BasicAmplifyConfiguration(hub: hubConfig)
    }

    func testGetOperation() throws {
        // Arrange
        let plugin = MockHubCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(mockAmplifyConfig)
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")
        // TODO: update notify to propagate the message to the message reporter mock to get individual
        // messages for the listeners, so we can check what it was, Progress vs Completed/Failed
        // instead of just 2 fulfillment counts
        methodWasInvokedOnPlugin.expectedFulfillmentCount = 2
        plugin.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodWasInvokedOnPlugin.fulfill()
            }
        }

        let mockStorageService = MockAWSS3StorageService()
        let request = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key").build()

        let completionInvoked = expectation(description: "completion was invoked on operation")
        let failedInvoked = expectation(description: "failed was invoked on operation")
        failedInvoked.isInverted = true

        let operation = AWSS3StorageGetOperation(request, service: mockStorageService, onEvent: { (event) in
            switch event {
            case .completed:
                completionInvoked.fulfill()
            case .failed:
                failedInvoked.fulfill()
            case .unknown:
                break
            case .notInProcess:
                break
            case .inProcess:
                break
            }
        })

        // Act
        operation.start()

        // Assert
        XCTAssertEqual(mockStorageService.executeGetRequestCalled, true)
        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1.0)
    }

    func testGetOperationError() {
        // Arrange
        // set up mock service to return failure.
    }
}
