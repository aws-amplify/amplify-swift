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

class AWSAPIPluginRESTClientBehaviorTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    override func tearDown() {
        Amplify.reset()
    }

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
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockHTTPTransportTask?
        mockTask = MockHTTPTransportTask(onResume: {
            guard let mockTask = mockTask else {
                return
            }
            mockTask.mockTransport?.delegate?.task(mockTask, didReceiveData: sentData)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockHTTPTransport = MockHTTPTransport(onTaskForRequest: { _ in task })
        Amplify.reset()
        setUpPlugin(with: mockHTTPTransport)

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
        let sentData = Data([0x00, 0x01, 0x02, 0x03])

        var mockTask: MockHTTPTransportTask?
        mockTask = MockHTTPTransportTask(onResume: {
            guard let mockTask = mockTask else {
                return
            }
            mockTask.mockTransport?.delegate?.task(mockTask, didReceiveData: sentData)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockHTTPTransport = MockHTTPTransport(onTaskForRequest: { _ in task })
        setUpPlugin(with: mockHTTPTransport)

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

    func setUpPlugin(with httpTransport: HTTPTransport? = nil) {
        let apiPlugin: AWSAPICategoryPlugin

        if let httpTransport = httpTransport {
            apiPlugin = AWSAPICategoryPlugin(httpTransport: httpTransport)
        } else {
            apiPlugin = AWSAPICategoryPlugin()
        }

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "Valid": [
                    "Endpoint": "https://example.apiforintegrationtests.com"
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

class MockHTTPTransport: HTTPTransport {
    weak var delegate: HTTPTransportTaskDelegate?

    var onTaskForRequest: (URLRequest) -> HTTPTransportTask
    var onReset: ((BasicClosure?) -> Void)?

    init(onTaskForRequest: @escaping (URLRequest) -> HTTPTransportTask,
         onReset: ((BasicClosure?) -> Void)? = nil) {
        self.onTaskForRequest = onTaskForRequest
        self.onReset = onReset
    }

    func task(for request: URLRequest) -> HTTPTransportTask {
        let task = onTaskForRequest(request)
        if let mockTask = task as? MockHTTPTransportTask {
            mockTask.mockTransport = self
        }
        return task
    }

    func reset(onComplete: BasicClosure?) {
        onReset?(onComplete)
    }
}

class MockHTTPTransportTask: HTTPTransportTask {
    static var counter = AtomicValue(initialValue: 0)

    /// Mimics a URLSessionTask's Session context, for dispatching events to the
    /// session delegate. Rather than use the transport as a broker, the tests should
    /// directly invoke the appropriate methods on the mockTransport's `delegate`
    weak var mockTransport: MockHTTPTransport?

    let taskIdentifier: Int

    var onCancel: BasicClosure?
    var onPause: BasicClosure?
    var onResume: BasicClosure?

    init(onCancel: BasicClosure? = nil,
         onPause: BasicClosure? = nil,
         onResume: BasicClosure? = nil) {
        self.onCancel = onCancel
        self.onPause = onPause
        self.onResume = onResume
        self.taskIdentifier = MockHTTPTransportTask.counter.increment()
    }

    func cancel() {
        onCancel?()
    }

    func pause() {
        onPause?()
    }

    func resume() {
        onResume?()
    }

}
