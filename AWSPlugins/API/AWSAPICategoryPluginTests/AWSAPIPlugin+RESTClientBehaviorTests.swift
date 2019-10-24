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

    func testGetReturnsOperation() {
        setUpPlugin()

        let operation = Amplify.API.get(apiName: "foo", path: "/path", listener: nil)

        XCTAssertNotNil(operation)

        guard operation is AWSAPIOperation else {
            XCTFail("operation could not be cast as AWSAPIGetOperation")
            return
        }

        XCTAssertNotNil(operation.request)
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
            mockTask.delegate?.task(mockTask, didReceiveData: sentData)
        })

        guard let task = mockTask else {
            XCTFail("mockTask unexpectedly nil")
            return
        }

        let mockHTTPTransport = MockHTTPTransport(onTaskForRequest: { _ in task })
        setUpPlugin(with: mockHTTPTransport)

        let callbackInvoked = expectation(description: "Callback was invoked")
        _ = Amplify.API.get(apiName: "foo", path: "/path") { event in
            switch event {
            case .completed(let data):
                XCTAssertEqual(data, sentData)
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
                "Prod": [
                    "Endpoint": "https://example.apiforintegrationtests.com"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

}

class MockHTTPTransport: HTTPTransport {
    var onTaskForRequest: (APIGetRequest) -> HTTPTransportTask
    var onReset: BasicClosure?

    init(onTaskForRequest: @escaping (APIGetRequest) -> HTTPTransportTask,
         onReset: BasicClosure? = nil) {
        self.onTaskForRequest = onTaskForRequest
        self.onReset = onReset
    }

    func task(for request: APIGetRequest) -> HTTPTransportTask {
        return onTaskForRequest(request)
    }

    func reset() {
        onReset?()
    }
}

class MockHTTPTransportTask: HTTPTransportTask {
    static var counter = AtomicValue(initialValue: 0)

    let taskIdentifier: Int

    weak var delegate: HTTPTransportTaskDelegate?

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
