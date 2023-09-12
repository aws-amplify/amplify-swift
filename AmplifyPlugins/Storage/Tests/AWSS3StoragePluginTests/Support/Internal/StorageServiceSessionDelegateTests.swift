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
    
    func testLogURLSession_withWarningTrue_shouldLogWarning() {
        delegate.logURLSessionActivity("message", warning: true)
        XCTAssertEqual(logger.warnCount, 1)
        XCTAssertEqual(logger.infoCount, 0)
    }
    
    func testLogURLSession_shouldLogInfo() {
        delegate.logURLSessionActivity("message")
        XCTAssertEqual(logger.warnCount, 0)
        XCTAssertEqual(logger.infoCount, 1)
    }

    func testDidFinishEvents_withMatchingIdentifiers_shouldRemoveContinuation() async {
        let expectation = self.expectation(description: "Did Finish Events")
        StorageBackgroundEventsRegistry.register(identifier: "identifier")
        Task {
            _ = await withCheckedContinuation { continuation in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(
                    identifier: "identifier",
                    continuation: continuation
                )
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.continuation)
        delegate.urlSessionDidFinishEvents(forBackgroundURLSession: .shared)
        XCTAssertNil(StorageBackgroundEventsRegistry.continuation)
    }
    
    func testDidFinishEvents_withNonMatchingIdentifiers_shouldRemoveContinuation() async {
        let expectation = self.expectation(description: "Did Finish Events")
        StorageBackgroundEventsRegistry.register(identifier: "identifier2")
        Task {
            _ = await withCheckedContinuation { continuation in
                StorageBackgroundEventsRegistry.handleBackgroundEvents(
                    identifier: "identifier2",
                    continuation: continuation
                )
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.continuation)
        delegate.urlSessionDidFinishEvents(forBackgroundURLSession: .shared)
        XCTAssertNotNil(StorageBackgroundEventsRegistry.continuation)
    }
    
    func testDidBecomeInvalid_withError_shouldResetURLSession() {
        delegate.urlSession(.shared, didBecomeInvalidWithError: StorageError.accessDenied("", "", nil))
        XCTAssertEqual(service.resetURLSessionCount, 1)
    }
    
    func testDidBecomeInvalid_withNilError_shouldResetURLSession() {
        delegate.urlSession(.shared, didBecomeInvalidWithError: nil)
        XCTAssertEqual(service.resetURLSessionCount, 1)
    }
    
    func testDidComplete_withNSURLErrorCancelled_shouldNotCompleteTask() {
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
            waitForExpectations(timeout: 1)
            XCTAssertEqual(storageTask.status, .unknown)
            XCTAssertEqual(service.unregisterCount, 0)
        }
    }
    
    func testDidComplete_withError_shouldFailTask() {
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
        waitForExpectations(timeout: 1)
        XCTAssertEqual(storageTask.status, .error)
        XCTAssertEqual(service.unregisterCount, 1)
    }
    
    func testDidSendBodyData_upload_shouldSendInProcessEvent() {
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
        
        waitForExpectations(timeout: 1)
    }
    
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
    
    func testDidWriteData_shouldNotifyProgress() {
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
        
        waitForExpectations(timeout: 1)
    }
    
    func testDiFinishDownloading_withError_shouldNotCompleteDownload() {
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
        
        waitForExpectations(timeout: 1)
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
