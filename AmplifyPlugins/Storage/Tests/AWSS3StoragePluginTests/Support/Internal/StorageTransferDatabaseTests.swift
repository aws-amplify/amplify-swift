//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify
import AmplifyTestCommon

// swiftlint:disable line_length

struct MockStorageURLSession: StorageURLSession {
    let sessionTasks: StorageSessionTasks

    func getActiveTasks(resultHandler: @escaping (StorageSessionTasks) -> Void) {
        resultHandler(sessionTasks)
    }
}

struct MockStorageSessionTask: StorageSessionTask {
    let taskIdentifier: TaskIdentifier
    let state: URLSessionTask.State

    init(taskIdentifier: TaskIdentifier, state: URLSessionTask.State = .suspended) {
        self.taskIdentifier = taskIdentifier
        self.state = state
    }
}

class StorageTransferDatabaseTests: XCTestCase {
    var fileSystem: FileSystem!
    var queue: DispatchQueue!
    var temporaryDirectoryURL: URL!
    var database: DefaultStorageTransferDatabase!
    var logger: Logger!

    let bucket = "MY_BUCKET"

    override func setUp() {
        fileSystem = FileSystem()
        queue = DispatchQueue(label: "com.amazon.aws.amplify.storage", qos: .background, target: .global())
        logger = storageLogger
        logger.logLevel = .info
        temporaryDirectoryURL = fileSystem.createTemporaryDirectoryURL()
        database = DefaultStorageTransferDatabase(databaseDirectoryURL: temporaryDirectoryURL, fileSystem: fileSystem, logger: logger)
    }

    override func tearDown() {
        fileSystem.removeDirectoryIfExists(directoryURL: temporaryDirectoryURL)

        fileSystem = nil
        queue = nil
        logger = nil
        temporaryDirectoryURL = nil
        database = nil
    }

    func testPersistingDatabase() throws {
        let downloadTask = createTask(transferType: .download(onEvent: mockDownloadEvent))
        let uploadTask = createTask(transferType: .upload(onEvent: mockUploadEvent))
        let multipartUploadTask = createTask(transferType: .multiPartUpload(onEvent: mockMultiPartUploadEvent))

        // set the session task and taskIdentifier
        var taskIdentifier = 0
        [downloadTask, uploadTask, multipartUploadTask].forEach { task in
            taskIdentifier += 1
            task.sessionTask = MockStorageSessionTask(taskIdentifier: taskIdentifier)
        }
    }

    func testStoringAndLoadingUploadTask() throws {
        let sessionTask = MockStorageSessionTask(taskIdentifier: 42)
        let originalTask = createTask(transferType: .upload(onEvent: mockUploadEvent))
        originalTask.sessionTask = sessionTask
        let fileURL = try database.storeTask(task: originalTask)
        let persistableTransferTask = try database.loadTask(fileURL: fileURL)

        guard let transferType = database.defaultTransferType(persistableTransferTask: persistableTransferTask) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask = StorageTransferTask(persistableTransferTask: persistableTransferTask,
                                             transferType: transferType,
                                             sessionTask: sessionTask)

        XCTAssertEqual(sessionTask.taskIdentifier, originalTask.taskIdentifier)
        XCTAssertEqual(sessionTask.taskIdentifier, persistableTransferTask.taskIdentifier)
        XCTAssertEqual(sessionTask.taskIdentifier, loadedTask.taskIdentifier)

        XCTAssertEqual(originalTask.transferID, persistableTransferTask.transferID)
        XCTAssertEqual(originalTask.transferID, loadedTask.transferID)
    }

    func testStoringAndLoadingDownloadTask() throws {
        let sessionTask = MockStorageSessionTask(taskIdentifier: 42)
        let originalTask = createTask(transferType: .download(onEvent: mockDownloadEvent))
        originalTask.sessionTask = sessionTask
        let fileURL = try database.storeTask(task: originalTask)
        let persistableTransferTask = try database.loadTask(fileURL: fileURL)

        guard let transferType = database.defaultTransferType(persistableTransferTask: persistableTransferTask) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask = StorageTransferTask(persistableTransferTask: persistableTransferTask,
                                             transferType: transferType,
                                             sessionTask: sessionTask)

        XCTAssertEqual(sessionTask.taskIdentifier, originalTask.taskIdentifier)
        XCTAssertEqual(sessionTask.taskIdentifier, persistableTransferTask.taskIdentifier)
        XCTAssertEqual(sessionTask.taskIdentifier, loadedTask.taskIdentifier)

        XCTAssertEqual(originalTask.transferID, persistableTransferTask.transferID)
        XCTAssertEqual(originalTask.transferID, loadedTask.transferID)
    }

    func testStoringAndLoadingPendingMultipartUploadTask() throws {
        let uploadId = UUID().uuidString

        let originalTask = createTask(transferType: .multiPartUpload(onEvent: mockMultiPartUploadEvent))
        originalTask.uploadId = uploadId

        let fileSize: UInt64 = UInt64(Bytes.megabytes(12).bytes)
        let uploadFile = UploadFile(fileURL: fileSystem.createTemporaryFileURL(), temporaryFileCreated: true, size: fileSize)
        let partSize = try StorageUploadPartSize(fileSize: uploadFile.size)
        let parts = try StorageUploadParts(fileSize: uploadFile.size, partSize: partSize, logger: logger)
        XCTAssertGreaterThanOrEqual(3, parts.count)

        let multipartUpload = StorageMultipartUpload.parts(uploadId: uploadId,
                                                           uploadFile: uploadFile,
                                                           partSize: partSize,
                                                           parts: parts)
        originalTask.multipartUpload = multipartUpload

        XCTAssertNotNil(originalTask.multipartUpload)

        let fileURL = try database.storeTask(task: originalTask)
        let persistableTransferTask = try database.loadTask(fileURL: fileURL)

        guard let transferType = database.defaultTransferType(persistableTransferTask: persistableTransferTask) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask = StorageTransferTask(persistableTransferTask: persistableTransferTask,
                                             transferType: transferType)

        XCTAssertNil(originalTask.taskIdentifier)
        XCTAssertNil(loadedTask.taskIdentifier)
        XCTAssertEqual(uploadId, originalTask.uploadId)
        XCTAssertEqual(uploadId, loadedTask.uploadId)
        XCTAssertNotNil(originalTask.multipartUpload)
        XCTAssertNotNil(loadedTask.multipartUpload)
    }

    func testStoringAndLoadingInProgressMultipartUploadTask() async throws {
        throw XCTSkip("Disables test which only fails with GitHub Actions")

        let uploadId = UUID().uuidString

        let originalTask = createTask(transferType: .multiPartUpload(onEvent: mockMultiPartUploadEvent))
        originalTask.uploadId = uploadId

        let fileSize: UInt64 = UInt64(Bytes.megabytes(12).bytes)
        let uploadFile = UploadFile(fileURL: fileSystem.createTemporaryFileURL(), temporaryFileCreated: true, size: fileSize)
        let partSize = try StorageUploadPartSize(fileSize: uploadFile.size)
        var parts = try StorageUploadParts(fileSize: uploadFile.size, partSize: partSize, logger: logger)
        XCTAssertGreaterThanOrEqual(3, parts.count)

        let taskIdentifier = 42
        var sessionTasks: [StorageSessionTask] = []

        // a StorageTransferTask must be created for each part which is inProgress
        for index in 0 ..< parts.count {
            let part = parts[index]

            if index <= 1 {
                let partNumber = index + 1
                let subTask = createSubTask(createMultipartUploadTask: originalTask,
                                            uploadId: uploadId,
                                            partNumber: partNumber)
                let sessionTask = MockStorageSessionTask(taskIdentifier: taskIdentifier + index)
                sessionTasks.append(sessionTask)
                subTask.sessionTask = sessionTask
                subTask.uploadPart = .pending(bytes: Bytes.megabytes(5).bytes)
                if index == 0 {
                    parts[index] = .inProgress(bytes: part.bytes,
                                               bytesTransferred: Int(Double(part.bytes) * 0.75),
                                               taskIdentifier: sessionTask.taskIdentifier)
                } else if index == 1 {
                    parts[index] = .inProgress(bytes: part.bytes,
                                               bytesTransferred: Int(Double(part.bytes) * 0.25),
                                               taskIdentifier: sessionTask.taskIdentifier)
                }
            } else {
                parts[index] = .queued(bytes: part.bytes)
            }
        }

        XCTAssertEqual(sessionTasks.count, 2)

        let multipartUpload = StorageMultipartUpload.parts(uploadId: uploadId,
                                                           uploadFile: uploadFile,
                                                           partSize: partSize,
                                                           parts: parts)
        originalTask.multipartUpload = multipartUpload

        XCTAssertEqual(database.tasksCount, 3)
        XCTAssertNotNil(originalTask.multipartUpload)

        let exp = AsyncExpectation.expectation(description: #function)

        var transferTaskPairs: StorageTransferTaskPairs?
        let urlSession = MockStorageURLSession(sessionTasks: sessionTasks)

        // trigger storing and then load to link tasks with sessions
        database.prepareForBackground { [weak self] in
            self?.database.recover(urlSession: urlSession) { result in
                do {
                    let pairs = try result.get()
                    XCTAssertTrue(!pairs.isEmpty)
                    transferTaskPairs = pairs
                } catch {
                    XCTFail("Error: \(error)")
                }
                Task {
                    await exp.fulfill()
                }
            }
        }

        try await AsyncExpectation.waitForExpectations([exp], timeout: 10.0)

        XCTAssertNotNil(transferTaskPairs)
        XCTAssertEqual(transferTaskPairs?.count, 3)

        // the initial task will not have a taskIdentifier
        guard let multipartUpload = transferTaskPairs?.first(where: { $0.transferTask.uploadId == uploadId && $0.transferTask.partNumber == nil }) else {
            XCTFail("Failed to get multipart upload")
            return
        }

        // upload part 1 will have a taskIdentifier
        guard let part1 = transferTaskPairs?.first(where: { $0.transferTask.partNumber == 1 }) else {
            XCTFail("Failed to get part 1")
            return
        }

        // upload part 1 will have a taskIdentifier
        guard let part2 = transferTaskPairs?.first(where: { $0.transferTask.partNumber == 2 }) else {
            XCTFail("Failed to get part 2")
            return
        }

        XCTAssertEqual(uploadId, multipartUpload.transferTask.uploadId)
        XCTAssertEqual(uploadId, part1.transferTask.uploadId)
        XCTAssertEqual(uploadId, part2.transferTask.uploadId)
        XCTAssertEqual(part1.transferTask.taskIdentifier, 42)
        XCTAssertEqual(part2.transferTask.taskIdentifier, 43)
    }

    // MARK: - Private -

    private func createTask(transferType: StorageTransferType) -> StorageTransferTask {
        StorageTransferTask(transferType: transferType,
                            bucket: bucket,
                            key: generatedKey(),
                            storageTransferDatabase: database,
                            logger: logger)
    }

    private func createSubTask(createMultipartUploadTask: StorageTransferTask,
                               uploadId: UploadID,
                               partNumber: PartNumber) -> StorageTransferTask {
        let transferType: StorageTransferType = .multiPartUploadPart(uploadId: uploadId, partNumber: partNumber)
        let subTask = StorageTransferTask(transferType: transferType,
                                          bucket: createMultipartUploadTask.bucket,
                                          key: createMultipartUploadTask.key,
                                          storageTransferDatabase: database,
                                          logger: logger)
        subTask.uploadId = uploadId
        return subTask
    }

    private func generatedKey() -> String {
        UUID().uuidString + ".key"
    }

    private var mockDownloadEvent: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler = { _ in  }
    private var mockUploadEvent: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler = { _ in }
    private var mockMultiPartUploadEvent: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler = { _ in }

}
