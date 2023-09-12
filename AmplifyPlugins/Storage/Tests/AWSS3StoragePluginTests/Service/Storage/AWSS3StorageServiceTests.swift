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

class AWSS3StorageServiceTests: XCTestCase {
    private var service: AWSS3StorageService!
    private var authService: MockAWSAuthService!
    private var database: StorageTransferDatabaseMock!
    private var task: StorageTransferTask!
    private var fileSystem: MockFileSystem!
    
    override func setUp() async throws {
        authService = MockAWSAuthService()
        database = StorageTransferDatabaseMock()
        fileSystem = MockFileSystem()
        task = StorageTransferTask(
            transferType: .download(onEvent: { _ in}),
            bucket: "bucket",
            key: "key"
        )
        task.uploadId = "uploadId"
        task.sessionTask = MockStorageSessionTask(taskIdentifier: 1)
        database.recoverResult = .success([
            .init(transferTask: task,
                  multipartUploads: [
                    .created(
                        uploadId: "uploadId",
                        uploadFile:UploadFile(
                            fileURL: FileSystem.default.createTemporaryFileURL(),
                            temporaryFileCreated: true,
                            size: UInt64(Bytes.megabytes(12).bytes)
                        )
                    )
                  ]
                 )
        ])
        service = try AWSS3StorageService(
            authService: authService,
            region: "region",
            bucket: "bucket",
            httpClientEngineProxy: MockHttpClientEngineProxy(),
            storageTransferDatabase: database,
            fileSystem: fileSystem,
            logger: MockLogger()
        )
    }
    
    override func tearDown() {
        authService = nil
        service = nil
        database = nil
        task = nil
        fileSystem = nil
    }
    
    func testDeinit_shouldUnregisterIdentifier() {
        XCTAssertNotNil(StorageBackgroundEventsRegistry.identifier)
        service = nil
        XCTAssertNil(StorageBackgroundEventsRegistry.identifier)
    }
    
    func testReset_shouldSetValuesToNil() {
        service.reset()
        XCTAssertNil(service.preSignedURLBuilder)
        XCTAssertNil(service.awsS3)
        XCTAssertNil(service.region)
        XCTAssertNil(service.bucket)
        XCTAssertTrue(service.tasks.isEmpty)
        XCTAssertTrue(service.multipartUploadSessions.isEmpty)
    }
    
    func testAttachEventHandlers() {
        let expectation = self.expectation(description: "Attach Event Handlers")
        service.attachEventHandlers(
            onUpload: { event in
                guard case .completed(_) = event else {
                    XCTFail("Expected completed")
                    return
                }
                expectation.fulfill()
            }
        )
        XCTAssertNotNil(database.onUploadHandler)
        database.onUploadHandler?(.completed(()))
        waitForExpectations(timeout: 1)
    }
    
    func testRegisterTask_shouldAddItToTasksDictionary() {
        service.register(task: task)
        XCTAssertEqual(service.tasks.count, 1)
        XCTAssertNotNil(service.tasks[1])
    }
    
    func testUnregisterTask_shouldRemoveItToTasksDictionary() {
        service.tasks = [
            1: task
        ]
        service.unregister(task: task)
        XCTAssertTrue(service.tasks.isEmpty)
        XCTAssertNil(service.tasks[1])
    }
    
    func testUnregisterTaskIdentifiers_shouldRemoveItToTasksDictionary() {
        service.tasks = [
            1: task,
            2: task
        ]
        service.unregister(taskIdentifiers: [1])
        XCTAssertEqual(service.tasks.count, 1)
        XCTAssertNotNil(service.tasks[2])
        XCTAssertNil(service.tasks[1])
    }
    
    func testFindTask_shouldReturnTask() {
        service.tasks = [
            1: task
        ]
        XCTAssertNotNil(service.findTask(taskIdentifier: 1))
    }
    
    func testValidateParameters_withEmptyBucket_shouldThrowError() {
        do {
            try service.validateParameters(bucket: "", key: "key", accelerationModeEnabled: true)
            XCTFail("Expected error")
        } catch {
            guard case .validation(let field, let description, let recovery, _) = error as? StorageError else {
                XCTFail("Expected StorageError.validation")
                return
            }
            XCTAssertEqual(field, "bucket")
            XCTAssertEqual(description, "Invalid bucket specified.")
            XCTAssertEqual(recovery, "Please specify a bucket name or configure the bucket property.")
        }
    }
    
    func testValidateParameters_withEmptyKey_shouldThrowError() {
        do {
            try service.validateParameters(bucket: "bucket", key: "", accelerationModeEnabled: true)
            XCTFail("Expected error")
        } catch {
            guard case .validation(let field, let description, let recovery, _) = error as? StorageError else {
                XCTFail("Expected StorageError.validation")
                return
            }
            XCTAssertEqual(field, "key")
            XCTAssertEqual(description, "Invalid key specified.")
            XCTAssertEqual(recovery, "Please specify a key.")
        }
    }
    
    func testValidateParameters_withValidParams_shouldNotThrowError() {
        do {
            try service.validateParameters(bucket: "bucket", key: "key", accelerationModeEnabled: true)
        } catch {
            XCTFail("Expected success, got \(error)")
        }
    }
    
    func testCreateTransferTask_shouldReturnTask() {
        let task = service.createTransferTask(
            transferType: .upload(onEvent: { event in }),
            bucket: "bucket",
            key: "key",
            requestHeaders: [
                "header": "value"
            ]
        )
        XCTAssertEqual(task.bucket, "bucket")
        XCTAssertEqual(task.key, "key")
        XCTAssertEqual(task.requestHeaders?.count, 1)
        XCTAssertEqual(task.requestHeaders?["header"], "value")
        guard case .upload(_) = task.transferType else {
            XCTFail("Expected .upload transferType")
            return
        }
    }
    
    func testCompleteDownload_shouldReturnData() {
        let expectation = self.expectation(description: "Complete Download")
       
        let downloadTask = StorageTransferTask(
            transferType: .download(onEvent: { event in
                guard case .completed(let data) = event,
                      let data = data else {
                    XCTFail("Expected .completed event with data")
                    return
                }
                XCTAssertEqual(String(decoding: data, as: UTF8.self), "someFile")
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )

        let sourceUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try! "someFile".write(to: sourceUrl, atomically: true, encoding: .utf8)

        service.tasks = [
            1: downloadTask
        ]

        service.completeDownload(taskIdentifier: 1, sourceURL: sourceUrl)
        XCTAssertEqual(downloadTask.status, .completed)
        waitForExpectations(timeout: 1)
    }
    
    func testCompleteDownload_withLocation_shouldMoveFileToLocation() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let location = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-newFile.txt")
       
        let downloadTask = StorageTransferTask(
            transferType: .download(onEvent: { _ in }),
            bucket: "bucket",
            key: "key",
            location: location
        )

        let sourceUrl = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-oldFile.txt")
        try! "someFile".write(to: sourceUrl, atomically: true, encoding: .utf8)

        service.tasks = [
            1: downloadTask
        ]

        service.completeDownload(taskIdentifier: 1, sourceURL: sourceUrl)
        XCTAssertTrue(FileManager.default.fileExists(atPath: location.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceUrl.path))
        XCTAssertEqual(downloadTask.status, .completed)
    }
    
    func testCompleteDownload_withLocation_andError_shouldFailTask() {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let location = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-newFile.txt")
       
        let downloadTask = StorageTransferTask(
            transferType: .download(onEvent: { _ in }),
            bucket: "bucket",
            key: "key",
            location: location
        )

        let sourceUrl = temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-oldFile.txt")
        try! "someFile".write(to: sourceUrl, atomically: true, encoding: .utf8)

        service.tasks = [
            1: downloadTask
        ]

        fileSystem.moveFileError = StorageError.unknown("Unable to move file", nil)
        service.completeDownload(taskIdentifier: 1, sourceURL: sourceUrl)
        XCTAssertFalse(FileManager.default.fileExists(atPath: location.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceUrl.path))
        XCTAssertEqual(downloadTask.status, .error)
    }
    
    func testCompleteDownload_withNoDownload_shouldDoNothing() {
        let expectation = self.expectation(description: "Complete Download")
        expectation.isInverted = true
       
        let uploadTask = StorageTransferTask(
            transferType: .upload(onEvent: { event in
                XCTFail("Should not report event")
                expectation.fulfill()
            }),
            bucket: "bucket",
            key: "key"
        )

        let sourceUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try! "someFile".write(to: sourceUrl, atomically: true, encoding: .utf8)

        service.tasks = [
            1: uploadTask
        ]

        service.completeDownload(taskIdentifier: 1, sourceURL: sourceUrl)
        XCTAssertNotEqual(uploadTask.status, .completed)
        XCTAssertNotEqual(uploadTask.status, .error)
        waitForExpectations(timeout: 1)
    }
    
    func testUpload_withoutPreSignedURL_shouldSendFailEvent() {
        let data = "someData".data(using: .utf8)!
        let expectation = self.expectation(description: "Upload")
        service.upload(
            serviceKey: "key",
            uploadSource: .data(data),
            contentType: "application/json",
            metadata: [:],
            accelerate: true,
            onEvent: { event in
                guard case .failed(let error) = event,
                      case .unknown(let description, _) = error else {
                    XCTFail("Expected .failed event with .unknown error, got \(event)")
                    return
                }
                XCTAssertEqual(description, "Failed to get pre-signed URL")
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: 1)
    }
    
    func testUpload_withPreSignedURL_shouldSendInitiatedEvent() {
        let data = "someData".data(using: .utf8)!
        let expectation = self.expectation(description: "Upload")
        service.preSignedURLBuilder = MockAWSS3PreSignedURLBuilder()
        service.upload(
            serviceKey: "key",
            uploadSource: .data(data),
            contentType: "application/json",
            metadata: [:],
            accelerate: true,
            onEvent: { event in
                guard case .initiated(_) = event else {
                    XCTFail("Expected .initiated event, got \(event)")
                    return
                }
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: 1)
    }
}

private class MockHttpClientEngineProxy: HttpClientEngineProxy {
    var target: HttpClientEngine? = nil

    var executeCount = 0
    var executeRequest: SdkHttpRequest?
    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        executeCount += 1
        executeRequest = request
        return .init(body: .empty, statusCode: .accepted)
    }
}

private class StorageTransferDatabaseMock: StorageTransferDatabase {
    
    func prepareForBackground(completion: (() -> Void)?) {
        completion?()
    }
    
    func insertTransferRequest(task: StorageTransferTask) {
        
    }
    
    func updateTransferRequest(task: StorageTransferTask) {
        
    }
    
    func removeTransferRequest(task: StorageTransferTask) {
        
    }
    
    func defaultTransferType(persistableTransferTask: StoragePersistableTransferTask) -> StorageTransferType? {
        return nil
    }
    
    var recoverCount = 0
    var recoverResult: Result<StorageTransferTaskPairs, Error> =  .failure(StorageError.unknown("Result not set", nil))
    func recover(urlSession: StorageURLSession,
                 completionHandler: @escaping (Result<StorageTransferTaskPairs, Error>) -> Void) {
        recoverCount += 1
        completionHandler(recoverResult)
    }
    
    var attachEventHandlersCount = 0
    var onUploadHandler: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler? = nil
    var onDownloadHandler: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler? = nil
    var onMultipartUploadHandler: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler? = nil
    func attachEventHandlers(
        onUpload: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler?,
        onDownload: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler?,
        onMultipartUpload: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler?
    ) {
        attachEventHandlersCount += 1
        onUploadHandler = onUpload
        onDownloadHandler = onDownload
        onMultipartUploadHandler = onMultipartUpload
    }
}

private class MockFileSystem: FileSystem {
    var moveFileError: Error? = nil
    override func moveFile(from sourceFileURL: URL, to destinationURL: URL) throws {
        if let moveFileError = moveFileError {
            throw moveFileError
        }
        try super.moveFile(from: sourceFileURL, to: destinationURL)
    }
}
