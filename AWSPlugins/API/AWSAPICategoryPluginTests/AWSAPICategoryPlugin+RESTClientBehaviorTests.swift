//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPICategoryPlugin
@testable import AWSPluginsTestCommon
@testable import AmplifyTestCommon

class AWSAPICategoryPluginRESTClientBehaviorTests: AWSAPICategoryPluginTestBase {

    // MARK: Get API tests

    func testGet() {
        let operation = apiPlugin.get(apiName: apiName, path: testPath, listener: nil)

        XCTAssertNotNil(operation)

        guard let getOperation = operation as? AWSAPIOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let request = getOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.path, testPath)
        XCTAssertNil(request.body)
        XCTAssertEqual(request.operationType, APIOperationType.get)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.path)
    }

    // MARK: Post API tests

    func testPost() {
        let operation = apiPlugin.post(apiName: apiName, path: testPath, body: testBody, listener: nil)

        XCTAssertNotNil(operation)

        guard let postOperation = operation as? AWSAPIOperation else {
            XCTFail("operation could not be cast to AWSAPIOperation")
            return
        }

        let request = postOperation.request
        XCTAssertNotNil(request)
        XCTAssertEqual(request.apiName, apiName)
        XCTAssertEqual(request.path, testPath)
        XCTAssertEqual(request.body, testBody)
        XCTAssertEqual(request.operationType, APIOperationType.post)
        XCTAssertNotNil(request.options)
        XCTAssertNotNil(request.path)
    }

    // MARK: Put API tests

    // MARK: Patch API tests

    // MARK: Delete API tests

    func testGetReturnsOperation() {
        setUpPlugin()

        let operation = Amplify.API.get(apiName: "Valid", path: "/path", listener: nil)

        XCTAssertNotNil(operation)

        guard operation is AWSAPIOperation else {
            XCTFail("operation could not be cast as AWSAPIGetOperation")
            return
        }

        XCTAssertNotNil(operation.request)
    }

    func testGetFailsWithBadAPIName() {
        Amplify.reset()

        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockURLSessionTask?
        mockTask = MockURLSessionTask(onResume: {
            guard let mockTask = mockTask,
                let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate else {
                    return
            }
            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)
            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory)

        let callbackInvoked = expectation(description: "Callback was invoked")
        _ = Amplify.API.get(apiName: "INVALID_API_NAME", path: "/path") { event in
            switch event {
            case .completed(let data):
                XCTFail("Unexpected completed event: \(data)")
            case .failed:
                // Expected failure
                break
            default:
                XCTFail("Unexpected event: \(event)")
            }
            callbackInvoked.fulfill()
        }

        wait(for: [callbackInvoked], timeout: 1.0)
    }

    /// - Given: A configured plugin
    /// - When: I invoke `APICategory.get(apiName:path:listener:)`
    /// - Then: The listener is invoked with the successful value
    func testGetReturnsValue() {
        Amplify.reset()

        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockURLSessionTask?
        mockTask = MockURLSessionTask(onResume: {
            guard let mockTask = mockTask,
                let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate else {
                    return
            }
            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: sentData)
            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let factory = MockSessionFactory(returning: mockSession)
        setUpPlugin(with: factory)

        let callbackInvoked = expectation(description: "Callback was invoked")
        _ = Amplify.API.get(apiName: "Valid", path: "/path") { event in
            switch event {
            case .completed(let data):
                XCTAssertEqual(data, sentData)
            case .failed(let error):
                XCTFail("Unexpected failure: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
            callbackInvoked.fulfill()
        }

        wait(for: [callbackInvoked], timeout: 1.0)
    }

    // MARK: - Utilities

    func setUpPlugin(with factory: URLSessionBehaviorFactory? = nil) {
        let apiPlugin: AWSAPICategoryPlugin

        if let factory = factory {
            apiPlugin = AWSAPICategoryPlugin(sessionFactory: factory)
        } else {
            apiPlugin = AWSAPICategoryPlugin()
        }

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "Valid": [
                    "Endpoint": "http://www.example.com",
                    "AuthorizationType": "API_KEY",
                    "ApiKey": "SpecialApiKey33"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            continueAfterFailure = false
            XCTFail("Error during setup: \(error)")
        }
    }

}
