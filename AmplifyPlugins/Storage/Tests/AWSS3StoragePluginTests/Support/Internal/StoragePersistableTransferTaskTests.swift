//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class StoragePersistableTransferTaskTests: XCTestCase {
    var database: StorageTransferDatabase!
    var fileSystem: FileSystem!
    var logger: Logger!

    override func setUp() {
        database = MockStorageTransferDatabase()
        fileSystem = FileSystem()
        logger = storageLogger
        logger.logLevel = .info
    }

    override func tearDown() {
        database = nil
        fileSystem = nil
        logger = nil
    }

    func testPersistingTransferTaskForUpload() throws {
        let sessionTask1 = MockStorageSessionTask(taskIdentifier: 1)
        let transferType1 = StorageTransferType.upload(onEvent: { _ in })
        let task1 = createTask(transferType: transferType1, sessionTask: nil)
        task1.sessionTask = sessionTask1
        let persistableTask1 = StoragePersistableTransferTask(task: task1)

        XCTAssertEqual(persistableTask1.transferTypeRawValue, transferType1.rawValue)
        XCTAssertEqual(task1.transferID, persistableTask1.transferID)
        XCTAssertEqual(task1.taskIdentifier, persistableTask1.taskIdentifier)

        XCTAssertNil(task1.multipartUpload)
        XCTAssertNil(task1.uploadPart)

        guard let loadedTranferType1 = database.defaultTransferType(persistableTransferTask: persistableTask1) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask1 = InternalStorageTransferTask(persistableTransferTask: persistableTask1,
                                              transferType: loadedTranferType1,
                                              sessionTask: sessionTask1,
                                              storageTransferDatabase: database,
                                              logger: logger)

        XCTAssertEqual(task1.transferID, loadedTask1.transferID)
        XCTAssertEqual(task1.taskIdentifier, loadedTask1.taskIdentifier)
        XCTAssertEqual(loadedTask1.transferID, persistableTask1.transferID)
        XCTAssertEqual(loadedTask1.taskIdentifier, persistableTask1.taskIdentifier)
    }

    func testPersistingTransferTaskForDownload() throws {
        let sessionTask1 = MockStorageSessionTask(taskIdentifier: 1)
        let transferType1 = StorageTransferType.download(onEvent: { _ in })
        let task1 = createTask(transferType: transferType1, sessionTask: nil)
        task1.sessionTask = sessionTask1
        let persistableTask1 = StoragePersistableTransferTask(task: task1)

        XCTAssertEqual(persistableTask1.transferTypeRawValue, transferType1.rawValue)
        XCTAssertEqual(task1.transferID, persistableTask1.transferID)
        XCTAssertEqual(task1.taskIdentifier, persistableTask1.taskIdentifier)

        XCTAssertNil(task1.multipartUpload)
        XCTAssertNil(task1.uploadPart)

        guard let loadedTranferType1 = database.defaultTransferType(persistableTransferTask: persistableTask1) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask1 = InternalStorageTransferTask(persistableTransferTask: persistableTask1,
                                              transferType: loadedTranferType1,
                                              sessionTask: sessionTask1,
                                              storageTransferDatabase: database,
                                              logger: logger)

        XCTAssertEqual(task1.transferID, loadedTask1.transferID)
        XCTAssertEqual(task1.taskIdentifier, loadedTask1.taskIdentifier)
        XCTAssertEqual(loadedTask1.transferID, persistableTask1.transferID)
        XCTAssertEqual(loadedTask1.taskIdentifier, persistableTask1.taskIdentifier)
    }

    func testPersistingTransferTaskForPendingMultipartUpload() throws {
        let uploadId = UUID().uuidString
        let fileURL = fileSystem.createTemporaryFileURL()
        let uploadFile = UploadFile(fileURL: fileURL,
                                    temporaryFileCreated: true,
                                    size: UInt64(Bytes.megabytes(12).bytes))

        let transferType1 = StorageTransferType.multiPartUpload(onEvent: { _ in })
        let task1 = createTask(transferType: transferType1, sessionTask: nil)

        task1.multipartUpload = .created(uploadId: uploadId, uploadFile: uploadFile)

        task1.uploadId = uploadId

        let persistableTask1 = StoragePersistableTransferTask(task: task1)

        XCTAssertEqual(persistableTask1.transferTypeRawValue, transferType1.rawValue)
        XCTAssertEqual(task1.transferID, persistableTask1.transferID)
        XCTAssertEqual(task1.uploadId, persistableTask1.uploadId)
    }

    func testPersistingTransferTaskForInProgressMultipartUpload() throws {
        let uploadId = UUID().uuidString
        let fileURL = fileSystem.createTemporaryFileURL()
        let uploadFile = UploadFile(fileURL: fileURL,
                                    temporaryFileCreated: true,
                                    size: UInt64(Bytes.megabytes(12).bytes))

        let transferType1 = StorageTransferType.multiPartUpload(onEvent: { _ in })
        let transferType2 = StorageTransferType.multiPartUploadPart(uploadId: uploadId, partNumber: 1)
        let transferType3 = StorageTransferType.multiPartUploadPart(uploadId: uploadId, partNumber: 2)

        let sessionTask2 = MockStorageSessionTask(taskIdentifier: 42)
        let sessionTask3 = MockStorageSessionTask(taskIdentifier: 43)

        let task1 = createTask(transferType: transferType1, sessionTask: nil)
        let task2 = createTask(transferType: transferType2, sessionTask: sessionTask2)
        let task3 = createTask(transferType: transferType3, sessionTask: sessionTask3)

        task1.multipartUpload = .created(uploadId: uploadId, uploadFile: uploadFile)
        task2.uploadPart = StorageUploadPart.pending(bytes: Bytes.megabytes(5).bytes)
        task3.uploadPart = StorageUploadPart.pending(bytes: Bytes.megabytes(5).bytes)

        task1.uploadId = uploadId
        task2.uploadId = uploadId
        task3.uploadId = uploadId

        let persistableTask1 = StoragePersistableTransferTask(task: task1)
        let persistableTask2 = StoragePersistableTransferTask(task: task2)
        let persistableTask3 = StoragePersistableTransferTask(task: task3)

        XCTAssertEqual(persistableTask1.transferTypeRawValue, transferType1.rawValue)
        XCTAssertEqual(persistableTask2.transferTypeRawValue, transferType2.rawValue)
        XCTAssertEqual(persistableTask3.transferTypeRawValue, transferType3.rawValue)

        XCTAssertEqual(task1.transferID, persistableTask1.transferID)
        XCTAssertEqual(task2.transferID, persistableTask2.transferID)
        XCTAssertEqual(task3.transferID, persistableTask3.transferID)

        XCTAssertEqual(task1.uploadId, persistableTask1.uploadId)
        XCTAssertEqual(task2.uploadId, persistableTask2.uploadId)
        XCTAssertEqual(task3.uploadId, persistableTask3.uploadId)

        XCTAssertEqual(task2.partNumber, persistableTask2.partNumber)
        XCTAssertEqual(task3.partNumber, persistableTask3.partNumber)

        XCTAssertNotNil(task1.multipartUpload)
        XCTAssertNil(task1.uploadPart)

        XCTAssertNil(task2.multipartUpload)
        XCTAssertNotNil(task2.uploadPart)

        XCTAssertNil(task3.multipartUpload)
        XCTAssertNotNil(task3.uploadPart)

        guard let loadedTranferType1 = database.defaultTransferType(persistableTransferTask: persistableTask1) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask1 = InternalStorageTransferTask(persistableTransferTask: persistableTask1,
                                              transferType: loadedTranferType1,
                                              storageTransferDatabase: database,
                                              logger: logger)

        XCTAssertNil(loadedTask1.taskIdentifier)
        XCTAssertEqual(task1.transferID, loadedTask1.transferID)
        XCTAssertEqual(task1.taskIdentifier, loadedTask1.taskIdentifier)
        XCTAssertEqual(loadedTask1.transferID, persistableTask1.transferID)
        XCTAssertEqual(loadedTask1.taskIdentifier, persistableTask1.taskIdentifier)

        guard let loadedTranferType2 = database.defaultTransferType(persistableTransferTask: persistableTask2) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask2 = InternalStorageTransferTask(persistableTransferTask: persistableTask2,
                                              transferType: loadedTranferType2,
                                              sessionTask: sessionTask2,
                                              storageTransferDatabase: database,
                                              logger: logger)

        XCTAssertEqual(task2.transferID, loadedTask2.transferID)
        XCTAssertEqual(task2.taskIdentifier, loadedTask2.taskIdentifier)
        XCTAssertEqual(loadedTask2.transferID, persistableTask2.transferID)
        XCTAssertEqual(loadedTask2.taskIdentifier, persistableTask2.taskIdentifier)

        guard let loadedTranferType3 = database.defaultTransferType(persistableTransferTask: persistableTask3) else {
            XCTFail("Failed to create default transfer type")
            return
        }

        let loadedTask3 = InternalStorageTransferTask(persistableTransferTask: persistableTask3,
                                              transferType: loadedTranferType3,
                                              sessionTask: sessionTask3,
                                              storageTransferDatabase: database,
                                              logger: logger)

        XCTAssertEqual(task3.transferID, loadedTask3.transferID)
        XCTAssertEqual(task3.taskIdentifier, loadedTask3.taskIdentifier)
        XCTAssertEqual(loadedTask3.transferID, persistableTask3.transferID)
        XCTAssertEqual(loadedTask3.taskIdentifier, persistableTask3.taskIdentifier)

        XCTAssertEqual(task1.uploadId, loadedTask1.uploadId)
        XCTAssertEqual(task2.uploadId, loadedTask2.uploadId)
        XCTAssertEqual(task3.uploadId, loadedTask3.uploadId)

        XCTAssertEqual(task2.partNumber, loadedTask2.partNumber)
        XCTAssertEqual(task3.partNumber, loadedTask3.partNumber)
    }

    // MARK: - Private -

    private func createTask(transferType: StorageTransferType,
                            sessionTask: StorageSessionTask? = nil) -> InternalStorageTransferTask {
        let transferID = UUID().uuidString
        let bucket = "BUCKET"
        let key = UUID().uuidString

        let task = InternalStorageTransferTask(transferID: transferID,
                                       transferType: transferType,
                                       bucket: bucket,
                                       key: key,
                                       location: nil,
                                       contentType: nil,
                                       requestHeaders: nil,
                                       storageTransferDatabase: database,
                                       logger: storageLogger)
        task.sessionTask = sessionTask
        return task
    }
}
