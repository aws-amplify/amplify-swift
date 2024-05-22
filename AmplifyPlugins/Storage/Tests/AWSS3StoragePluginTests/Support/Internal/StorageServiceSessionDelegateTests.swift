//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin
import ClientRuntime
import AWSS3
import XCTest

class StorageServiceSessionDelegateTests: XCTestCase {
    private var delegate: StorageServiceSessionDelegate!
    private var service: AWSS3StorageServiceMock!
    private var logger: MockLogger!
    
    override func setUp() {
        service = try! AWSS3StorageServiceMock()
        logger = MockLogger()
        delegate = StorageServiceSessionDelegate(
            identifier: "delegateTest",
            logger: logger
        )
        delegate.storageService = service
    }
    
    override func tearDown() {
        logger = nil
        service = nil
        delegate = nil
    }
    
    /// Given: A StorageServiceSessionDelegate
    /// When: logURLSessionActivity is invoked with warning set to true
    /// Then: A warn message is logged
    func testLogURLSession_withWarningTrue_shouldLogWarning() {
        delegate.logURLSessionActivity("message", warning: true)
        XCTAssertEqual(logger.warnCount, 1)
        XCTAssertEqual(logger.infoCount, 0)
    }
    
    /// Given: A StorageServiceSessionDelegate
    /// When: logURLSessionActivity is invoked without setting warning
    /// Then: An info message is logged
    func testLogURLSession_shouldLogInfo() {
        delegate.logURLSessionActivity("message")
        XCTAssertEqual(logger.warnCount, 0)
        XCTAssertEqual(logger.infoCount, 1)
    }

    /// Given: A StorageServiceSessionDelegate and an identifier registered in the registry
    /// When: the registry's handleBackgroundEvents is invoked with a matching identifier and then urlSessionDidFinishEvents is invoked
    /// Then: The registry's  continuation is triggered with true
    func testDidFinishEvents_withMatchingIdentifiers_shouldTriggerContinuationWithTrue() async {
        let handleEventsExpectation = self.expectation(description: "Handle Background Events")
        let finishEventsExpectation = self.expectation(description: "Did Finish Events")
        StorageBackgroundEventsRegistry.register(identifier: "identifier")
        Task {
            let result = await withCheckedContinuation { continuation in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(
                    identifier: "identifier",
                    continuation: continuation
                )
                handleEventsExpectation.fulfill()
            }
            XCTAssertTrue(result)
            finishEventsExpectation.fulfill()
        }
        
        await fulfillment(of: [handleEventsExpectation], timeout: 1)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.continuation)
        delegate.urlSessionDidFinishEvents(forBackgroundURLSession: .shared)
        await fulfillment(of: [finishEventsExpectation], timeout: 1)
        XCTAssertNil(StorageBackgroundEventsRegistry.continuation)
    }
    
    /// Given: A StorageServiceSessionDelegate and an identifier registered in the registry
    /// When: the registry's handleBackgroundEvents is invoked first with a matching identifier and then with a non-matching one, and after that urlSessionDidFinishEvents is invoked
    /// Then: The registry's continuation for the non-matching identifier is triggered immediately with false, while the one for the matching identifier is triggered with true only after urlSessionDidFinishEvents is invoked
    func testDidFinishEvents_withNonMatchingIdentifiers_shouldTriggerContinuationWithFalse() async {
        let handleEventsMatchingExpectation = self.expectation(description: "Handle Background Events with Matching Identifiers")
        let finishEventsExpectation = self.expectation(description: "Did Finish Events")
        StorageBackgroundEventsRegistry.register(identifier: "identifier")
        Task {
            let result = await withCheckedContinuation { continuation in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(
                    identifier: "identifier",
                    continuation: continuation
                )
                handleEventsMatchingExpectation.fulfill()
            }
            XCTAssertTrue(result)
            finishEventsExpectation.fulfill()
        }
        
        await fulfillment(of: [handleEventsMatchingExpectation], timeout: 1)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.continuation)
        
        let handleEventsNonMatchingExpectation = self.expectation(description: "Handle Background Events with Matching Identifiers")
        Task {
            let result = await withCheckedContinuation { continuation in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(
                    identifier: "identifier2",
                    continuation: continuation
                )
            }
            XCTAssertFalse(result)
            handleEventsNonMatchingExpectation.fulfill()
        }
        await fulfillment(of: [handleEventsNonMatchingExpectation], timeout: 1)
        delegate.urlSessionDidFinishEvents(forBackgroundURLSession: .shared)
        await fulfillment(of: [finishEventsExpectation], timeout: 1)
        XCTAssertNil(StorageBackgroundEventsRegistry.continuation)
    }
    
    /// Given: A StorageServiceSessionDelegate
    /// When: didBecomeInvalidWithError is invoked with a StorageError
    /// Then: The service's resetURLSession is invoked
    func testDidBecomeInvalid_withError_shouldResetURLSession() {
        delegate.urlSession(.shared, didBecomeInvalidWithError: StorageError.accessDenied("", "", nil))
        XCTAssertEqual(service.resetURLSessionCount, 1)
    }
    
    /// Given: A StorageServiceSessionDelegate
    /// When: didBecomeInvalidWithError is invoked with a nil error
    /// Then: The service's resetURLSession is invoked
    func testDidBecomeInvalid_withNilError_shouldResetURLSession() {
        delegate.urlSession(.shared, didBecomeInvalidWithError: nil)
        XCTAssertEqual(service.resetURLSessionCount, 1)
    }
    
    /// Given: A StorageServiceSessionDelegate and a StorageTransferTask with a NSError with a NSURLErrorCancelled reason
    /// When: didComplete is invoked
    /// Then: The task is not unregistered
    func testDidComplete_withNSURLErrorCancelled_shouldNotCompleteTask() async {
        let task = URLSession.shared.dataTask(with: FileManager.default.temporaryDirectory)
        let reasons = [
            NSURLErrorCancelledReasonBackgroundUpdatesDisabled,
            NSURLErrorCancelledReasonInsufficientSystemResources,
            NSURLErrorCancelledReasonUserForceQuitApplication,
            NSURLErrorCancelled
        ]
        
        for reason in reasons {
            let expectation = self.expectation(description: "Did Complete With Error Reason \(reason)")
            expectation.isInverted = true
            let storageTask = StorageTransferTask(
                transferType: .upload(onEvent: { _ in
                    expectation.fulfill()
                }),
                bucket: "bucket",
                key: "key"
            )
            service.mockedTask = storageTask
            let error: Error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorCancelled,
                userInfo: [
                    NSURLErrorBackgroundTaskCancelledReasonKey: reason
                ]
            )
            
            delegate.urlSession(.shared, task: task, didCompleteWithError: error)
            
            await fulfillment(of: [expectation], timeout: 5)
          
            XCTAssertEqual(storageTask.status, .unknown)
            XCTAssertEqual(service.unregisterCount, 0)
        }
    }
    
    /// Given: A StorageServiceSessionDelegate and a StorageTransferTask with a StorageError
    /// When: didComplete is invoked
    /// Then: The task status is set to error and it's unregistered
    func testDidComplete_withError_shouldFailTask() async {
        let task = URLSession.shared.dataTask(with: FileManager.default.temporaryDirectory)
        let expectation = self.expectation(description: "Did Complete With Error")
        let storageTask = StorageTransferTask(
            transferType: .upload(onEvent: { _ in
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )
        service.mockedTask = storageTask
        
        delegate.urlSession(.shared, task: task, didCompleteWithError: StorageError.accessDenied("", "", nil))
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(storageTask.status, .error)
        XCTAssertEqual(service.unregisterCount, 1)
    }
    
    /// Given: A StorageServiceSessionDelegate and a StorageTransferTask of type .upload
    /// When: didSendBodyData is invoked
    /// Then: An .inProcess event is reported, with the corresponding values
    func testDidSendBodyData_upload_shouldSendInProcessEvent() async {
        let task = URLSession.shared.dataTask(with: FileManager.default.temporaryDirectory)
        let expectation = self.expectation(description: "Did Send Body Data")
        let storageTask = StorageTransferTask(
            transferType: .upload(onEvent: { event in
                guard case .inProcess(let progress) = event else {
                    XCTFail("Expected .inProcess event, got \(event)")
                    return
                }
                XCTAssertEqual(progress.totalUnitCount, 120)
                XCTAssertEqual(progress.completedUnitCount, 100)
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )
        service.mockedTask = storageTask
        
        delegate.urlSession(
            .shared,
            task: task,
            didSendBodyData: 10,
            totalBytesSent: 100,
            totalBytesExpectedToSend: 120
        )
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A StorageServiceSessionDelegate and a StorageTransferTask of type .multiPartUploadPart
    /// When: didSendBodyData is invoked
    /// Then: A .progressUpdated event is reported to the session
    func testDidSendBodyData_multiPartUploadPart_shouldSendInProcessEvent() {
        let task = URLSession.shared.dataTask(with: FileManager.default.temporaryDirectory)
        let storageTask = StorageTransferTask(
            transferType: .multiPartUploadPart(
                uploadId: "uploadId",
                partNumber: 3
            ),
            bucket: "bucket",
            key: "key"
        )
        service.mockedTask = storageTask
        let multipartSession = MockStorageMultipartUploadSession(
            client: MockMultipartUploadClient(),
            bucket: "bucket",
            key: "key",
            onEvent: { event in }
        )
        service.mockedMultipartUploadSession = multipartSession
        
        delegate.urlSession(
            .shared,
            task: task,
            didSendBodyData: 10,
            totalBytesSent: 100,
            totalBytesExpectedToSend: 120
        )
        XCTAssertEqual(multipartSession.handleUploadPartCount, 1)
        guard case .progressUpdated(let partNumber, let bytesTransferred, let taskIdentifier) = multipartSession.lastUploadEvent else {
            XCTFail("Expected .progressUpdated event")
            return
        }
        
        XCTAssertEqual(partNumber, 3)
        XCTAssertEqual(bytesTransferred, 10)
        XCTAssertEqual(taskIdentifier, task.taskIdentifier)
    }
    
    /// Given: A StorageServiceSessionDelegate and a StorageTransferTask of type .download
    /// When: didWriteData is invoked
    /// Then: An .inProcess event is reported, with the corresponding values
    func testDidWriteData_shouldNotifyProgress() async {
        let task = URLSession.shared.downloadTask(with: FileManager.default.temporaryDirectory)
        let expectation = self.expectation(description: "Did Write Data")
        let storageTask = StorageTransferTask(
            transferType: .download(onEvent: { event in
                guard case .inProcess(let progress) = event else {
                    XCTFail("Expected .inProcess event, got \(event)")
                    return
                }
                XCTAssertEqual(progress.totalUnitCount, 300)
                XCTAssertEqual(progress.completedUnitCount, 200)
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )
        service.mockedTask = storageTask
        
        delegate.urlSession(
            .shared,
            downloadTask: task,
            didWriteData: 15,
            totalBytesWritten: 200,
            totalBytesExpectedToWrite: 300
        )
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: A StorageServiceSessionDelegate and a URLSessionDownloadTask without a httpResponse
    /// When: didFinishDownloadingTo is invoked
    /// Then: No event is reported and the task is not completed
    func testDiFinishDownloading_withError_shouldNotCompleteDownload() async {
        let task = URLSession.shared.downloadTask(with: FileManager.default.temporaryDirectory)
        let expectation = self.expectation(description: "Did Finish Downloading")
        expectation.isInverted = true
        let storageTask = StorageTransferTask(
            transferType: .download(onEvent: { _ in
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )
        service.mockedTask = storageTask
        
        delegate.urlSession(
            .shared,
            downloadTask: task,
            didFinishDownloadingTo: FileManager.default.temporaryDirectory
        )
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(service.completeDownloadCount, 0)
    }
}

private class AWSS3StorageServiceMock: AWSS3StorageService {
    convenience init() throws {
        try self.init(
            authService: MockAWSAuthService(),
            region: "region",
            bucket: "bucket",
            storageTransferDatabase: MockStorageTransferDatabase()
        )
    }
    
    override var identifier: String {
        return "identifier"
    }
    
    var mockedTask: StorageTransferTask? = nil
    override func findTask(taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        return mockedTask
    }
    
    var resetURLSessionCount = 0
    override func resetURLSession() {
        resetURLSessionCount += 1
    }
    
    var unregisterCount = 0
    override func unregister(task: StorageTransferTask) {
        unregisterCount += 1
    }
    
    var mockedMultipartUploadSession: StorageMultipartUploadSession? = nil
    override func findMultipartUploadSession(uploadId: UploadID) -> StorageMultipartUploadSession? {
        return mockedMultipartUploadSession
    }
    
    var completeDownloadCount = 0
    override func completeDownload(taskIdentifier: TaskIdentifier, sourceURL: URL) {
        completeDownloadCount += 1
    }
}
