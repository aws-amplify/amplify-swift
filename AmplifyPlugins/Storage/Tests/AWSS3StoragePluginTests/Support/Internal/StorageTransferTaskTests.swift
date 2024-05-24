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
    /// Given: A StorageTransferTask with a sessionTask
    /// When: resume is invoked
    /// Then: an .initiated event is reported and the task set to .inProgress
    func testResume_withSessionTask_shouldCallResume_andReportInitiatedEvent() async {
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
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(sessionTask.resumeCount, 1)
        XCTAssertEqual(task.status, .inProgress)
    }

    /// Given: A StorageTransferTask with a proxyStorageTask
    /// When: resume is invoked
    /// Then: an .initiated event is reported and the task set to .inProgress
    func testResume_withProxyStorageTask_shouldCallResume_andReportInitiatedEvent() async {
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
            sessionTask: sessionTask, // Set the sessionTask to set task.status = .paused
            proxyStorageTask: storageTask
        )
        task.sessionTask = nil // Remove the session task
        XCTAssertEqual(task.status, .paused)
        
        task.resume()
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(sessionTask.resumeCount, 0)
        XCTAssertEqual(storageTask.resumeCount, 1)
        XCTAssertEqual(task.status, .inProgress)
    }

    /// Given: A StorageTransferTask with a sessionTask and a proxyStorageTask
    /// When: resume is invoked
    /// Then: an .initiated event is reported and the task set to .inProgress
    func testResume_withSessionTask_andProxyStorageTask_shouldCallResume_andReportInitiatedEvent() async {
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
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(sessionTask.resumeCount, 1)
        XCTAssertEqual(storageTask.resumeCount, 0)
        XCTAssertEqual(task.status, .inProgress)
    }

    /// Given: A StorageTransferTask without a sessionTask and without a proxyStorageTask
    /// When: resume is invoked
    /// Then: No event is reported and the task is not to .inProgress
    func testResume_withoutSessionTask_withoutProxyStorateTask_shouldNotCallResume_andNotReportEvent() async {
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
        await fulfillment(of: [expectation], timeout: 0.5)

        XCTAssertEqual(sessionTask.resumeCount, 0)
        XCTAssertEqual(task.status, .paused)
    }
    
    /// Given: A StorageTransferTask with status not being paused
    /// When: resume is invoked
    /// Then: No event is reported and the task is not set to .inProgress
    func testResume_withTaskNotPaused_shouldNotCallResume_andNotReportEvent() async {
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
        await fulfillment(of: [expectation], timeout: 0.5)
        
        XCTAssertEqual(task.status, .unknown)
    }

    // MARK: - Suspend Tests
    /// Given: A StorageTransferTask with a sessionTask
    /// When: suspend is invoked
    /// Then: The task is set to .paused
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

    /// Given: A StorageTransferTask with a proxyStorageTask
    /// When: suspend is invoked
    /// Then: The task is set to .paused
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

    /// Given: A StorageTransferTask with a sessionTask and a proxyStorageTask
    /// When: suspend is invoked
    /// Then: The task is set to .paused
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
    
    /// Given: A StorageTransferTask without a sessionTask and without a proxyStorageTask
    /// When: suspend is invoked
    /// Then: The task remains .inProgress
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
    
    /// Given: A StorageTransferTask with status completed
    /// When: suspend is invoked
    /// Then: The task remains completed
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
    
    /// Given: A StorageTransferTask
    /// When: pause is invoked
    /// Then: The task is set to .paused
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
    /// Given: A StorageTransferTask with a sessionTask
    /// When: cancel is invoked
    /// Then: The task is set to .cancelled
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
    
    /// Given: A StorageTransferTask with a proxyStorageTask
    /// When: cancel is invoked
    /// Then: The task is set to .cancelled
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

    /// Given: A StorageTransferTask without a sessionTask and without a proxyStorageTask
    /// When: cancel is invoked
    /// Then: The task is not set to .cancelled
    func testCancel_withoutSessionTask_withoutProxyStorageTask_shouldDoNothing() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in }),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        
        task.cancel()
        XCTAssertNotEqual(task.status, .cancelled)
    }

    /// Given: A StorageTransferTask with status completed
    /// When: cancel is invoked
    /// Then: The task is not set to .cancelled
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
        XCTAssertNotEqual(task.status, .cancelled)
        XCTAssertEqual(sessionTask.cancelCount, 0)
        XCTAssertNotNil(task.proxyStorageTask)
    }

    // MARK: - Complete Tests
    /// Given: A StorageTransferTask with sessionTask
    /// When: complete is invoked
    /// Then: The task is set to .completed
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

    /// Given: A StorageTransferTask with status cancelled
    /// When: complete is invoked
    /// Then: The task is remains .cancelled
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
    
    /// Given: A StorageTransferTask with status completed
    /// When: complete is invoked
    /// Then: The task is remains .completed
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
    /// Given: A StorageTransferTask
    /// When: fail is invoked
    /// Then: A .failed event is reported
    func testFail_shouldReportFailEvent() async {
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

        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(task.status, .error)
        XCTAssertTrue(task.isFailed)
        XCTAssertNil(task.proxyStorageTask)
    }
    
    /// Given: A StorageTransferTask with status .failed
    /// When: fail is invoked
    /// Then: No event is reported
    func testFail_withFailedTask_shouldNotReportEvent() async {
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

        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertNotNil(task.proxyStorageTask)
    }
    
    // MARK: - Response Tests
    /// Given: A StorageTransferTask with a valid responseData
    /// When: responseText is invoked
    /// Then: A string representing the data is returned
    func testResponseText_withValidData_shouldReturnText() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        task.responseData = Data("Test".utf8)

        XCTAssertEqual(task.responseText, "Test")
    }
    
    /// Given: A StorageTransferTask with an invalid responseData
    /// When: responseText is invoked
    /// Then: nil is returned
    func testResponseText_withInvalidData_shouldReturnNil() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )
        task.responseData = Data(count: 9999)

        XCTAssertNil(task.responseText)
    }
    
    /// Given: A StorageTransferTask with a nil responseData
    /// When: responseText is invoked
    /// Then: nil is returned
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
    /// Given: A StorageTransferTask of type .multiPartUploadPart
    /// When: partNumber is invoked
    /// Then: The corresponding part number is returned
    func testPartNumber_withMultipartUpload_shouldReturnPartNumber() {
        let partNumber: PartNumber = 5
        let task = createTask(
            transferType: .multiPartUploadPart(uploadId: "", partNumber: partNumber),
            sessionTask: nil,
            proxyStorageTask: nil
        )

        XCTAssertEqual(task.partNumber, partNumber)
    }
    
    /// Given: A StorageTransferTask of type .upload
    /// When: partNumber is invoked
    /// Then: nil is returned
    func testPartNumber_withOtherTransferType_shouldReturnNil() {
        let task = createTask(
            transferType: .upload(onEvent: { _ in}),
            sessionTask: nil,
            proxyStorageTask: nil
        )

        XCTAssertNil(task.partNumber)
    }

    // MARK: - HTTPRequestHeaders Tests
    /// Given: A StorageTransferTask with requestHeaders
    /// When: URLRequest.setHTTPRequestHeaders is invoked with said task
    /// Then: The request includes the corresponding headers
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
    
    /// Given: A StorageTransferTask with nil requestHeaders
    /// When: URLRequest.setHTTPRequestHeaders is invoked with said task
    /// Then: The request does not adds headers
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
