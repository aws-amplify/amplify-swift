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
    
    /// Given: An AWSS3StorageService
    /// When: it's deallocated
    /// Then: StorageBackgroundEventsRegistry.identifier should be set to nil
    func testDeinit_shouldUnregisterIdentifier() {
        XCTAssertNotNil(StorageBackgroundEventsRegistry.identifier)
        service = nil
        XCTAssertNil(StorageBackgroundEventsRegistry.identifier)
    }
    
    /// Given: An AWSS3StorageService
    /// When: reset is invoked
    /// Then: Its members should be set to nil
    func testReset_shouldSetValuesToNil() {
        service.reset()
        XCTAssertNil(service.preSignedURLBuilder)
        XCTAssertNil(service.awsS3)
        XCTAssertNil(service.region)
        XCTAssertNil(service.bucket)
        XCTAssertTrue(service.tasks.isEmpty)
        XCTAssertTrue(service.multipartUploadSessions.isEmpty)
    }
    
    /// Given: An AWSS3StorageService
    /// When: attachEventHandlers is invoked and a .completed event is sent
    /// Then: A .completed event is dispatched to the event handler
    func testAttachEventHandlers() async {
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
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: An AWSS3StorageService
    /// When: register is invoked with a task
    /// Then: The task should be added to its map of tasks
    func testRegisterTask_shouldAddItToTasksDictionary() {
        service.register(task: task)
        XCTAssertEqual(service.tasks.count, 1)
        XCTAssertNotNil(service.tasks[1])
    }
    
    /// Given: An AWSS3StorageService with a task in its map of tasks
    /// When: unregister is invoked with said task
    /// Then: The task should be removed from the map of tasks
    func testUnregisterTask_shouldRemoveItToTasksDictionary() {
        service.tasks = [
            1: task
        ]
        service.unregister(task: task)
        XCTAssertTrue(service.tasks.isEmpty)
        XCTAssertNil(service.tasks[1])
    }
    
    /// Given: An AWSS3StorageService with some tasks in its map of tasks
    /// When: unregister is invoked with an identifier that is known to be mapped to a task.
    /// Then: The task corresponding to the given identifier should be removed from the map of tasks
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
    
    /// Given: An AWSS3StorageService with a task in its map of tasks
    /// When: findTask is invoked with the identifier known to be mapped to a task
    /// Then: The task corresponding to the given identifier is returned
    func testFindTask_shouldReturnTask() {
        service.tasks = [
            1: task
        ]
        XCTAssertNotNil(service.findTask(taskIdentifier: 1))
    }
    
    /// Given: An AWSS3StorageService
    /// When: validateParameters is invoked with an empty bucket parameter
    /// Then: A .validation error is thrown
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
    
    /// Given: An AWSS3StorageService
    /// When: validateParameters is invoked with an empty key parameter
    /// Then: A .validation error is thrown
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
    
    /// Given: An AWSS3StorageService
    /// When: validateParameters is invoked with valid bucket and key parameters
    /// Then: No error is thrown
    func testValidateParameters_withValidParams_shouldNotThrowError() {
        do {
            try service.validateParameters(bucket: "bucket", key: "key", accelerationModeEnabled: true)
        } catch {
            XCTFail("Expected success, got \(error)")
        }
    }
    
    /// Given: An AWSS3StorageService
    /// When: createTransferTask is invoked with valid parameters
    /// Then: A task is returned with attributes matching the ones provided
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
    
    /// Given: An AWSS3StorageService with a non-completed download task
    /// When: completeDownload is invoked for the identifier matching the task
    /// Then: The task is marked as completed and a .completed event is dispatched
    func testCompleteDownload_shouldReturnData() async {
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
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: An AWSS3StorageService with a non-completed download task that sets a location
    /// When: completeDownload is invoked for the identifier matching the task
    /// Then: The task is marked as completed and the file is moved to the expected location
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
    
    /// Given: An AWSS3StorageService with a non-completed download task that sets a location
    /// When: completeDownload is invoked for the identifier matching the task, but the file system fails to move the file
    /// Then: The task is marked as error and the file is not moved to the expected location
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
    
    /// Given: An AWSS3StorageService with a non-completed upload task that sets a location
    /// When: completeDownload is invoked for the identifier matching the task
    /// Then: The task status is not updated and an .upload event is not dispatched
    func testCompleteDownload_withNoDownload_shouldDoNothing() async {
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
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: An AWSS3StorageService that cannot create a pre signed url
    /// When: upload is invoked
    /// Then: A .failed event is dispatched with an .unknown error
    func testUpload_withoutPreSignedURL_shouldSendFailEvent() async {
        let data = Data("someData".utf8)
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
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    /// Given: An AWSS3StorageService that can create a pre signed url
    /// When: upload is invoked
    /// Then: An .initiated event is dispatched
    func testUpload_withPreSignedURL_shouldSendInitiatedEvent() async {
        let data = Data("someData".utf8)
        let expectation = self.expectation(description: "Upload")
        service.preSignedURLBuilder = MockAWSS3PreSignedURLBuilder()
        service.upload(
            serviceKey: "key",
            uploadSource: .data(data),
            contentType: "application/json",
            metadata: [:],
            accelerate: true,
            onEvent: { event in
                if case .initiated(_) = event {
                    expectation.fulfill()
                }
            }
        )
        
        await fulfillment(of: [expectation], timeout: 1)
    }
}

private class MockHttpClientEngineProxy: HttpClientEngineProxy {
    var target: HTTPClient? = nil

    var executeCount = 0
    var executeRequest: SdkHttpRequest?
    func send(request: SdkHttpRequest) async throws -> HttpResponse {
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
