//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSS3StoragePlugin
import XCTest

class StorageTransferTaskTests: XCTestCase {

    // MARK: - Resume tests
    func testResume_withSessionTask_shouldCallResume_andReportInitiatedEvent() {
        let expectation = expectation(description: ".initiated event received on resume with only sessionTask")
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { event in
                guard case .initiated(_) = event else {
                    XCTFail("Expected .initiated, got \(event)")
                    return
                }
                expectation.fulfill()
            }),
            sessionTask: sessionTask,
            proxyStorageTask: nil
        )
        XCTAssertEqual(task.status, .paused)
        
        task.resume()
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(sessionTask.resumeCount, 1)
        XCTAssertEqual(task.status, .inProgress)
    }

    func testResume_withProxyStorageTask_shouldCallResume_andReportInitiatedEvent() {
        let expectation = expectation(description: ".initiated event received on resume with only proxyStorageTask")
        let sessionTask = MockSessionTask()
        let storageTask = MockStorageTask()
        let task = createTask(
            transferType: .download(onEvent: { event in
                guard case .initiated(_) = event else {
                    XCTFail("Expected .initiated, got \(event)")
                    return
                }
                expectation.fulfill()
            }),
            sessionTask: sessionTask, // Set the sessioTask to set task.status = .paused
            proxyStorageTask: storageTask
        )
        task.sessionTask = nil // Remove the session task
        XCTAssertEqual(task.status, .paused)
        
        task.resume()
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(sessionTask.resumeCount, 0)
        XCTAssertEqual(storageTask.resumeCount, 1)
        XCTAssertEqual(task.status, .inProgress)
    }

    func testResume_withSessionTask_andProxyStorageTask_shouldCallResume_andReportInitiatedEvent() {
        let expectation = expectation(description: ".initiated event received on resume with sessionTask and proxyStorageTask")
        let sessionTask = MockSessionTask()
        let storageTask = MockStorageTask()
        let task = createTask(
            transferType: .multiPartUpload(onEvent: { event in
                guard case .initiated(_) = event else {
                    XCTFail("Expected .initiated, got \(event)")
                    return
                }
                expectation.fulfill()
            }),
            sessionTask: sessionTask,
            proxyStorageTask: storageTask
        )
        XCTAssertEqual(task.status, .paused)
        
        task.resume()
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(sessionTask.resumeCount, 1)
        XCTAssertEqual(storageTask.resumeCount, 0)
        XCTAssertEqual(task.status, .inProgress)
    }

    func testResume_withoutSessionTask_withoutProxyStorateTask_shouldNotCallResume_andNotReportEvent() {
        let expectation = expectation(description: "no event is received on resume when no sessionTask nor proxyStorageTask")
        expectation.isInverted = true
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .multiPartUpload(onEvent: { event in
                XCTFail("No event expected, got \(event)")
                expectation.fulfill()
            }),
            sessionTask: sessionTask, // Set the sessionTask to set task.status = .paused
            proxyStorageTask: nil
        )
        task.sessionTask = nil // Remove the sessionTask
        XCTAssertEqual(task.status, .paused)
        
        task.resume()
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(sessionTask.resumeCount, 0)
        XCTAssertEqual(task.status, .paused)
    }
    
    func testResume_withTaskNotPaused_shouldNotCallResume_andNotReportEvent() {
        let expectation = expectation(description: "no event is received on resume when the session is not paused")
        expectation.isInverted = true
        let task = createTask(
            transferType: .multiPartUpload(onEvent: { event in
                XCTFail("No event expected, got \(event)")
                expectation.fulfill()
            }),
            sessionTask: nil, // Do not set session task so task.status = .unknown
            proxyStorageTask: nil
        )
        XCTAssertEqual(task.status, .unknown)
        
        task.resume()
        waitForExpectations(timeout: 0.5)
        
        XCTAssertEqual(task.status, .unknown)
    }

    // MARK: - Suspend Tests
    func testSuspend_withSessionTask_shouldCallSuspend() {
        let sessionTask = MockSessionTask(state: .running)
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: nil
        )
        // Set the task to inProgress by setting a multiPartUpload.creating
        task.multipartUpload = .creating
        XCTAssertEqual(task.status, .inProgress)

        task.suspend()

        XCTAssertEqual(sessionTask.suspendCount, 1)
        XCTAssertEqual(task.status, .paused)
    }

    func testSuspend_withProxyStorageTask_shouldCallPause() {
        let storageTask = MockStorageTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: nil,
            proxyStorageTask: storageTask
        )
        // Set the task to inProgress by setting a multiPartUpload.creating
        task.multipartUpload = .creating
        XCTAssertEqual(task.status, .inProgress)

        task.suspend()

        XCTAssertEqual(storageTask.pauseCount, 1)
        XCTAssertEqual(task.status, .paused)
    }

    func testSuspend_withSessionTask_andProxyStorageTask_shouldCallSuspend() {
        let sessionTask = MockSessionTask(state: .running)
        let storageTask = MockStorageTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: storageTask
        )
        // Set the task to inProgress by setting a multiPartUpload.creating
        task.multipartUpload = .creating
        XCTAssertEqual(task.status, .inProgress)

        task.suspend()

        XCTAssertEqual(sessionTask.suspendCount, 1)
        XCTAssertEqual(storageTask.pauseCount, 0)
        XCTAssertEqual(task.status, .paused)
    }
    
    func testSuspend_withoutSessionTask_andWithoutProxyStorageTask_shouldDoNothing() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        // Set the task to inProgress by setting a multiPartUpload.creating
        task.multipartUpload = .creating
        XCTAssertEqual(task.status, .inProgress)

        task.suspend()

        XCTAssertEqual(task.status, .inProgress)
    }
    
    func testSuspend_withTaskNotInProgress_shouldDoNothing() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: nil
        )
        // Set the task to completed by setting a multiPartUpload.completed
        task.multipartUpload = .completed(uploadId: "")
        XCTAssertEqual(task.status, .completed)

        task.suspend()

        XCTAssertEqual(sessionTask.suspendCount, 0)
        XCTAssertEqual(task.status, .completed)
    }
    
    func testPause_shouldCallSuspend() {
        let sessionTask = MockSessionTask(state: .running)
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: nil
        )
        // Set the task to inProgress by setting a multiPartUpload.creating
        task.multipartUpload = .creating
        XCTAssertEqual(task.status, .inProgress)

        task.pause()

        XCTAssertEqual(sessionTask.suspendCount, 1)
        XCTAssertEqual(task.status, .paused)
    }

    // MARK: - Cancel Tests
    func testCancel_withSessionTask_shouldCancel() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: MockStorageTask()
        )
        
        // Set the task to completed by setting a multiPartUpload.completed
        XCTAssertNotEqual(task.status, .completed)
        
        task.cancel()

        XCTAssertEqual(task.status, .cancelled)
        XCTAssertEqual(sessionTask.cancelCount, 1)
        XCTAssertNil(task.proxyStorageTask)
    }

    func testCancel_withProxyStorageTask_shouldCancel() {
        let storageTask = MockStorageTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: nil,
            proxyStorageTask: storageTask
        )
        
        task.cancel()
        XCTAssertEqual(task.status, .cancelled)
        XCTAssertEqual(storageTask.cancelCount, 1)
        XCTAssertNil(task.proxyStorageTask)
    }

    func testCancel_withoutSessionTask_withoutProxyStorageTask_shouldDoNothing() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        
        task.cancel()
        XCTAssertNotEqual(task.status, .cancelled)
    }

    func testCancel_withTaskCompleted_shouldDoNothing() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: MockStorageTask()
        )
        // Set the task to completed by setting a multiPartUpload.completed
        task.multipartUpload = .completed(uploadId: "")
        XCTAssertEqual(task.status, .completed)
        
        task.cancel()
        XCTAssertEqual(sessionTask.cancelCount, 0)
        XCTAssertNotNil(task.proxyStorageTask)
    }

    // MARK: - Complete Tests
    func testComplete_withSessionTask_shouldComplete() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: MockStorageTask()
        )
        
        task.complete()
        XCTAssertEqual(task.status, .completed)
        XCTAssertNil(task.proxyStorageTask)
    }

    func testComplete_withTaskCancelled_shouldDoNothing() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: nil
        )
        task.cancel()
        XCTAssertEqual(task.status, .cancelled)
       
        task.complete()
        XCTAssertEqual(task.status, .cancelled)
    }
    
    func testComplete_withTaskCompleted_shouldDoNothing() {
        let sessionTask = MockSessionTask()
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: sessionTask,
            proxyStorageTask: MockStorageTask()
        )
        // Set the task to completed by setting a multiPartUpload.completed
        task.multipartUpload = .completed(uploadId: "")
        XCTAssertEqual(task.status, .completed)
        
        task.complete()

        XCTAssertNotNil(task.proxyStorageTask)
    }
    
    // MARK: - Fail Tests
    func testFail_shouldReportFailEvent() {
        let expectation = expectation(description: ".failed event received on fail")
        let task = createTask(
            transferType: .upload(onEvent: { event in
                guard case .failed(_) = event else {
                    XCTFail("Expected .failed, got \(event)")
                    return
                }
                expectation.fulfill()
            }),
            sessionTask: MockSessionTask(),
            proxyStorageTask: MockStorageTask()
        )
        task.fail(error: CancellationError())

        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(task.status, .error)
        XCTAssertTrue(task.isFailed)
        XCTAssertNil(task.proxyStorageTask)
    }
    
    func testFail_withFailedTask_shouldNotReportEvent() {
        let expectation = expectation(description: "event received on fail for failed task")
        expectation.isInverted = true
        let task = createTask(
            transferType: .upload(onEvent: { event in
                XCTFail("No event expected, got \(event)")
                expectation.fulfill()
            }),
            sessionTask: MockSessionTask(),
            proxyStorageTask: MockStorageTask()
        )
        
        // Set the task to error by setting a multiPartUpload.failed
        task.multipartUpload = .failed(uploadId: "", parts: nil, error: CancellationError())
        XCTAssertEqual(task.status, .error)
        task.fail(error: CancellationError())

        waitForExpectations(timeout: 0.5)
        XCTAssertNotNil(task.proxyStorageTask)
    }
    
    // MARK: - Response Tests
    func testResponseText_withValidData_shouldReturnText() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        task.responseData = "Test".data(using: .utf8)
        
        XCTAssertEqual(task.responseText, "Test")
    }
    
    func testResponseText_withInvalidData_shouldReturnNil() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        task.responseData = Data(count: 9999)

        XCTAssertNil(task.responseText)
    }
    
    func testResponseText_withoutData_shouldReturnNil() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        task.responseData = nil

        XCTAssertNil(task.responseText)
    }
    
    // MARK: - PartNumber Tests
    func testPartNumber_withMultipartUpload_shouldReturnPartNumber() {
        let partNumber: PartNumber = 5
        let task = createTask(
            transferType: .multiPartUploadPart(uploadId: "", partNumber: partNumber),
            sessionTask: nil,
            proxyStorageTask: nil
        )

        XCTAssertEqual(task.partNumber, partNumber)
    }
    
    func testPartNumber_withOtherTransferType_shouldReturnNil() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )

        XCTAssertNil(task.partNumber)
    }

    // MARK: - HTTPRequestHeaders Tests
    func testHTTPRequestHeaders_shouldSetValues() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil,
            requestHeaders: [
                "header1": "value1",
                "header2": "value2"
            ]
        )

        var request = URLRequest(url: FileManager.default.temporaryDirectory)
        XCTAssertNil(request.allHTTPHeaderFields)
        
        request.setHTTPRequestHeaders(transferTask: task)
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 2)
        XCTAssertEqual(request.allHTTPHeaderFields?["header1"], "value1")
        XCTAssertEqual(request.allHTTPHeaderFields?["header2"], "value2")
    }
    
    func testHTTPRequestHeaders_withoutHeaders_shouldDoNothing() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil,
            requestHeaders: nil
        )

        var request = URLRequest(url: FileManager.default.temporaryDirectory)
        XCTAssertNil(request.allHTTPHeaderFields)
        
        request.setHTTPRequestHeaders(transferTask: task)
        XCTAssertNil(request.allHTTPHeaderFields)
    }
}

extension StorageTransferTaskTests {
    private func createTask(
        transferType: StorageTransferType,
        sessionTask: StorageSessionTask?,
        proxyStorageTask: StorageTask?,
        requestHeaders: [String: String]? = nil
    ) -> StorageTransferTask {
        let transferID = UUID().uuidString
        let bucket = "BUCKET"
        let key = UUID().uuidString
        let task = StorageTransferTask(
            transferID: transferID,
            transferType: transferType,
            bucket: bucket,
            key: key,
            location: nil,
            contentType: nil,
            requestHeaders: requestHeaders,
            storageTransferDatabase: MockStorageTransferDatabase(),
            logger: MockLogger()
        )
        task.sessionTask = sessionTask
        task.proxyStorageTask = proxyStorageTask
        return task
    }
}


private class MockStorageTask: StorageTask {
    var pauseCount = 0
    func pause() {
        pauseCount += 1
    }
    
    var resumeCount = 0
    func resume() {
        resumeCount += 1
    }
    
    var cancelCount = 0
    func cancel() {
        cancelCount += 1
    }
}

private class MockSessionTask: StorageSessionTask {
    let taskIdentifier: TaskIdentifier
    let state: URLSessionTask.State

    init(
        taskIdentifier: TaskIdentifier = 1,
        state: URLSessionTask.State = .suspended
    ) {
        self.taskIdentifier = taskIdentifier
        self.state = state
    }
    
    var resumeCount = 0
    func resume() {
        resumeCount += 1
    }
    
    var suspendCount = 0
    func suspend() {
        suspendCount += 1
    }
    
    var cancelCount = 0
    func cancel() {
        cancelCount += 1
    }
}

class MockLogger: Logger {
    var logLevel: LogLevel = .verbose
    
    func error(_ message: @autoclosure () -> String) {
        print(message())
    }
    
    func error(error: Error) {
        print(error)
    }
    
    var warnCount = 0
    func warn(_ message: @autoclosure () -> String) {
        print(message())
        warnCount += 1
    }
    
    var infoCount = 0
    func info(_ message: @autoclosure () -> String) {
        print(message())
        infoCount += 1
    }
    
    func debug(_ message: @autoclosure () -> String) {
        print(message())
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        print(message())
    }
}
