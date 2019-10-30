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

struct MockSessionFactory: URLSessionBehaviorFactory {
    let session: MockURLSession

    init(returning session: MockURLSession) {
        self.session = session
    }

    func makeSession(withDelegate delegate: URLSessionBehaviorDelegate?) -> URLSessionBehavior {
        session.sessionBehaviorDelegate = delegate
        return session
    }
}

class MockURLSession: URLSessionBehavior {
    weak var sessionBehaviorDelegate: URLSessionBehaviorDelegate?

    static let defaultOnReset: ((BasicClosure?) -> Void) = { $0?() }

    var onTaskForRequest: (URLRequest) -> URLSessionDataTaskBehavior
    var onReset: ((BasicClosure?) -> Void)?

    init(onTaskForRequest: @escaping (URLRequest) -> URLSessionDataTaskBehavior,
         onReset: ((BasicClosure?) -> Void)? = MockURLSession.defaultOnReset) {
        self.onTaskForRequest = onTaskForRequest
        self.onReset = onReset
    }

    func dataTaskBehavior(with request: URLRequest) -> URLSessionDataTaskBehavior {
        let task = onTaskForRequest(request)
        if let mockTask = task as? MockURLSessionTask {
            mockTask.mockSession = self
        }
        return task
    }

    func reset(onComplete: BasicClosure?) {
        onReset?(onComplete)
    }
}

class MockURLSessionTask: URLSessionDataTaskBehavior {
    static var counter = AtomicValue(initialValue: 0)

    /// Mimics a URLSessionTask's Session context, for dispatching events to the
    /// session delegate. Rather than use the mock session as a broker, the tests
    /// should directly invoke the appropriate methods on the mockSession's
    /// `delegate`
    weak var mockSession: MockURLSession?

    let taskBehaviorIdentifier: Int

    var onCancel: BasicClosure?
    var onPause: BasicClosure?
    var onResume: BasicClosure?

    init(onCancel: BasicClosure? = nil,
         onPause: BasicClosure? = nil,
         onResume: BasicClosure? = nil) {
        self.onCancel = onCancel
        self.onPause = onPause
        self.onResume = onResume
        self.taskBehaviorIdentifier = MockURLSessionTask.counter.increment()
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
