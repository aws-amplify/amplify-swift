//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSS3StoragePlugin
import XCTest

class DefaultStorageTransferDatabaseTests: XCTestCase {
    private var database: DefaultStorageTransferDatabase!
    private var uploadFile: UploadFile!
    private var session: MockStorageSessionTask!

    override func setUp() {
        database = DefaultStorageTransferDatabase(
            databaseDirectoryURL: FileManager.default.temporaryDirectory,
            logger: MockLogger()
        )
        uploadFile = UploadFile(
            fileURL: FileSystem.default.createTemporaryFileURL(),
            temporaryFileCreated: true,
            size: UInt64(Bytes.megabytes(12).bytes)
        )
        session = MockStorageSessionTask(taskIdentifier: 1)
    }

    override func tearDown() {
        database = nil
        uploadFile = nil
        session = nil
    }

    /// Given: A DefaultStorageTransferDatabase
    /// When: linkTasksWithSessions is invoked with tasks containing multipart uploads and a sessionTask, and a session
    /// Then: A StorageTransferTaskPairs linking the tasks with the session is returned
    func testLinkTasksWithSessions_withMultipartUpload_shouldReturnPairs() {
        let transferTask1 = StorageTransferTask(
            transferType: .multiPartUpload(onEvent: { _ in }),
            bucket: "bucket",
            key: "key1"
        )
        transferTask1.sessionTask = session
        transferTask1.multipartUpload = .created(
            uploadId: "uploadId",
            uploadFile: uploadFile
        )

        let transferTask2 = StorageTransferTask(
            transferType: .multiPartUpload(onEvent: { _ in }),
            bucket: "bucket",
            key: "key2"
        )
        transferTask2.sessionTask = session
        transferTask2.multipartUpload = .created(
            uploadId: "uploadId",
            uploadFile: uploadFile
        )

        let pairs = database.linkTasksWithSessions(
            persistableTransferTasks: [
                "taskId1": .init(task: transferTask1),
                "taskId2": .init(task: transferTask2)
            ],
            sessionTasks: [
                session
            ]
        )

        XCTAssertEqual(pairs.count, 2)
        XCTAssertTrue(pairs.contains(where: { $0.transferTask.key == "key1" }))
        XCTAssertTrue(pairs.contains(where: { $0.transferTask.key == "key2" }))
    }

    /// Given: A DefaultStorageTransferDatabase
    /// When: linkTasksWithSessions is invoked with tasks containing multipart uploads but without a sessionTask, and a session
    /// Then: A StorageTransferTaskPairs linking the tasks with the session is returned
    func testLinkTasksWithSessions_withMultipartUpload_andNoSession_shouldReturnPairs() {
        let transferTask1 = StorageTransferTask(
            transferType: .multiPartUpload(onEvent: { _ in }),
            bucket: "bucket",
            key: "key1"
        )
        transferTask1.multipartUpload = .created(
            uploadId: "uploadId",
            uploadFile: uploadFile
        )

        let transferTask2 = StorageTransferTask(
            transferType: .multiPartUpload(onEvent: { _ in }),
            bucket: "bucket",
            key: "key2"
        )
        transferTask2.multipartUpload = .created(
            uploadId: "uploadId",
            uploadFile: uploadFile
        )

        let pairs = database.linkTasksWithSessions(
            persistableTransferTasks: [
                "taskId1": .init(task: transferTask1),
                "taskId2": .init(task: transferTask2)
            ],
            sessionTasks: [
                session
            ]
        )

        XCTAssertEqual(pairs.count, 2)
        XCTAssertTrue(pairs.contains(where: { $0.transferTask.key == "key1" }))
        XCTAssertTrue(pairs.contains(where: { $0.transferTask.key == "key2" }))
    }

    /// Given: A DefaultStorageTransferDatabase
    /// When: linkTasksWithSessions is invoked with tasks containing multipart upload parts, and a session
    /// Then: A StorageTransferTaskPairs linking the tasks with the session is returned
    func testLinkTasksWithSessions_withMultipartUploadPart_shouldReturnPairs() {
        let transferTask0 = StorageTransferTask(
            transferType: .multiPartUpload(onEvent: { _ in }),
            bucket: "bucket",
            key: "key1"
        )
        transferTask0.sessionTask = session
        transferTask0.multipartUpload = .created(
            uploadId: "uploadId",
            uploadFile: uploadFile
        )

        let transferTask1 = StorageTransferTask(
            transferType: .multiPartUploadPart(
                uploadId: "uploadId",
                partNumber: 1
            ),
            bucket: "bucket",
            key: "key1"
        )
        transferTask1.sessionTask = session
        transferTask1.uploadId = "uploadId"
        transferTask1.multipartUpload = .parts(
            uploadId: "uploadId",
            uploadFile: uploadFile,
            partSize: try! .init(fileSize: UInt64(Bytes.megabytes(6).bytes)),
            parts: [
                .inProgress(
                    bytes: Bytes.megabytes(6).bytes,
                    bytesTransferred: Bytes.megabytes(3).bytes,
                    taskIdentifier: 1
                ),
                .completed(
                    bytes: Bytes.megabytes(6).bytes,
                    eTag: "eTag")
                ,
                .pending(bytes: Bytes.megabytes(6).bytes)
            ]
        )
        transferTask1.uploadPart = .completed(
            bytes: Bytes.megabytes(6).bytes,
            eTag: "eTag"
        )

        let transferTask2 = StorageTransferTask(
            transferType: .multiPartUploadPart(
                uploadId: "uploadId",
                partNumber: 2
            ),
            bucket: "bucket",
            key: "key1"
        )
        transferTask2.sessionTask = session
        transferTask2.uploadId = "uploadId"
        transferTask2.multipartUpload = .parts(
            uploadId: "uploadId",
            uploadFile: uploadFile,
            partSize: try! .init(fileSize: UInt64(Bytes.megabytes(6).bytes)),
            parts: [
                .pending(bytes: Bytes.megabytes(6).bytes),
                .pending(bytes: Bytes.megabytes(6).bytes)
            ]
        )
        transferTask2.uploadPart = .inProgress(
            bytes: Bytes.megabytes(6).bytes,
            bytesTransferred: Bytes.megabytes(3).bytes,
            taskIdentifier: 1
        )

        let pairs = database.linkTasksWithSessions(
            persistableTransferTasks: [
                "taskId0": .init(task: transferTask0),
                "taskId1": .init(task: transferTask1),
                "taskId2": .init(task: transferTask2)
            ],
            sessionTasks: [
                session
            ]
        )

        XCTAssertEqual(pairs.count, 3)
        XCTAssertTrue(pairs.contains(where: { $0.transferTask.key == "key1" }))
        XCTAssertFalse(pairs.contains(where: { $0.transferTask.key == "key2" }))
    }

    /// Given: A DefaultStorageTransferDatabase
    /// When: recover is invoked with a StorageURLSession that returns a session
    /// Then: A .success is returned
    func testLoadPersistableTasks() async {
        let urlSession = MockStorageURLSession(
            sessionTasks: [
                session
            ])
        let expectation = self.expectation(description: "Recover")
        database.recover(urlSession: urlSession) { result in
            guard case .success(_) = result else {
                XCTFail("Expected success")
                return
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }

    /// Given: A DefaultStorageTransferDatabase
    /// When: prepareForBackground is invoked
    /// Then: A callback is invoked
    func testPrepareForBackground() async {
        let expectation = self.expectation(description: "Prepare for Background")
        database.prepareForBackground() {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)
    }

    /// Given: The StorageTransferDatabase Type
    /// When: default is invoked
    /// Then: An instance of DefaultStorageTransferDatabase is returned
    func testDefault_shouldReturnDefaultInstance() {
        let defaultProtocol: StorageTransferDatabase = .default
        XCTAssertTrue(defaultProtocol is DefaultStorageTransferDatabase)
    }
}
