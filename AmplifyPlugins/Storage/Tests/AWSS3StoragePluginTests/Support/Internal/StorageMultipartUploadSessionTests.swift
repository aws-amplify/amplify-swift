//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class StorageMultipartUploadSessionTests: XCTestCase {
    enum Failure: Error {
        case unableToCreateData
        case testFailure
    }

    func testSessionCreation() throws {
        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated:
                print("Initiated")
            case .inProcess(let progress):
                print("Progress: \(String(format: "%.2f", progress.fractionCompleted))")
            case .failed:
                print("Failed")
                XCTFail("Must not fail")
            case .completed:
                print("Completed")
            }
        }

        let client = MockMultipartUploadClient()
        let session = StorageMultipartUploadSession(client: client, bucket: bucket, key: key, onEvent: onEvent)
        XCTAssertEqual(session.partsCount, 0)
        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertFalse(session.partsCompleted)
        XCTAssertFalse(session.partsFailed)
    }

    func testFullMultipartUploadSession() throws {
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated:
                print("Initiated")
                initiatedExp.fulfill()
            case .inProcess(let progress):
                print("Progress: \(String(format: "%.2f", progress.fractionCompleted))")
            case .failed(let error):
                print("Error: \(error)")
                XCTFail("Must not fail")
            case .completed:
                print("Completed")
                completedExp.fulfill()
            }
        }

        let client = MockMultipartUploadClient() // creates an UploadFile for the mock process
        let session = StorageMultipartUploadSession(client: client, bucket: bucket, key: key, onEvent: onEvent)

        session.startUpload()

        wait(for: [initiatedExp, completedExp], timeout: 300.0)

        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertTrue(session.isCompleted)

        XCTAssertEqual(client.completeMultipartUploadCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.errorCount, 0)
        XCTAssertGreaterThan(client.uploadPartCount, 0)
    }

    private func createFile() throws -> URL {
        let size = minimumPartSize
        let parts: [String] = [
            Array(repeating: "a", count: size).joined(),
            Array(repeating: "b", count: size).joined(),
            Array(repeating: "c", count: size).joined(),
            Array(repeating: "d", count: size).joined(),
            Array(repeating: "e", count: size).joined(),
            Array(repeating: "f", count: size / 2).joined()
        ]
        let string = parts.joined()

        guard let data = string.data(using: .utf8) else {
            XCTFail("Failed to create data for file")
            throw Failure.unableToCreateData
        }

        let fileURL = try FileSystem.default.createTemporaryFile(data: data)
        return fileURL
    }

//    func testSessionToCompleted() throws {
//        let client = MockMultipartUploadClient()
//        var session = StorageMultipartUploadSession(client: client)
//
//        // 1) Send event from creating a multipart upload
//        let fileURL = URL(string: "/tmp/image.jpg")!
//        let uploadFile = UploadFile(fileURL: fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(250).bytes))
//        let uploadId = UUID().uuidString
//        try session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
//        XCTAssertTrue(session.multipartUpload.hasParts)
//        print("parts: \(session.parts.count)")
//        XCTAssertEqual(session.session.partsCount, 0)
//        XCTAssertFalse(session.parts.isDone)
//
//        // 2) Send events to complete each part
//        for (index, part) in session.parts.enumerated() {
//            let number = index + 1
//            let taskIdentifier = index + 100
//            try session.handle(uploadPartEvent: .started(number: number, taskIdentifier: taskIdentifier))
//            try session.handle(uploadPartEvent: .progressUpdated(number: number, bytesTransferred: part.bytes / 2))
//            try session.handle(uploadPartEvent: .completed(number: number))
//        }
//        XCTAssertTrue(session.parts.isDone)
//
//        // 3) Send event to complete multipart upload
//        try session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
//        XCTAssertTrue(session.multipartUpload.isCompleted)
//        XCTAssertFalse(session.multipartUpload.isAborted)
//    }

//    func testSessionToAborted() throws {
//        let client = MockMultipartUploadClient()
//        var session = StorageMultipartUploadSession(client: client)
//
//        // 1) Send event from creating a multipart upload
//        let fileURL = URL(string: "/tmp/image.jpg")!
//        let uploadFile = UploadFile(fileURL: fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(250).bytes))
//        let uploadId = UUID().uuidString
//        try session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
//        XCTAssertTrue(session.multipartUpload.hasParts)
//        print("parts: \(session.parts.count)")
//        XCTAssertFalse(session.parts.isEmpty)
//        XCTAssertFalse(session.parts.isDone)
//
//        // 2) Send events to complete each part
//        for (index, part) in session.parts.enumerated() {
//            let number = index + 1
//            let taskIdentifier = index + 100
//            try session.handle(uploadPartEvent: .started(number: number, taskIdentifier: taskIdentifier))
//            try session.handle(uploadPartEvent: .progressUpdated(number: number, bytesTransferred: part.bytes / 2))
//            try session.handle(uploadPartEvent: .completed(number: number))
//        }
//        XCTAssertTrue(session.parts.isDone)
//
//        // 3) Send event to abort multipart upload
//        try session.handle(multipartUploadEvent: .aborted(uploadId: uploadId))
//        XCTAssertFalse(session.multipartUpload.isCompleted)
//        XCTAssertTrue(session.multipartUpload.isAborted)
//    }
//
//    func testSessionToFailure() throws {
//        let client = MockMultipartUploadClient()
//        var session = StorageMultipartUploadSession(client: client)
//
//        // 1) Send event from creating a multipart upload
//        let fileURL = URL(string: "/tmp/image.jpg")!
//        let uploadFile = UploadFile(fileURL: fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(250).bytes))
//        let uploadId = UUID().uuidString
//        try session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
//        XCTAssertTrue(session.multipartUpload.hasParts)
//        print("parts: \(session.parts.count)")
//        XCTAssertFalse(session.parts.isEmpty)
//        XCTAssertFalse(session.parts.isDone)
//
//        // 2) Send event to fail multipart upload
//        try session.handle(multipartUploadEvent: .failed(uploadId: uploadId, error: Failure.testFailure))
//        XCTAssertFalse(session.multipartUpload.isCompleted)
//        XCTAssertFalse(session.multipartUpload.isAborted)
//        XCTAssertTrue(session.multipartUpload.isFailed)
//    }
//
//    func testSessionWithPartFailure() throws {
//        let client = MockMultipartUploadClient()
//        var session = StorageMultipartUploadSession(client: client)
//
//        // 1) Send event from creating a multipart upload
//        let fileURL = URL(string: "/tmp/image.jpg")!
//        let uploadFile = UploadFile(fileURL: fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(250).bytes))
//        let uploadId = UUID().uuidString
//        try session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
//        XCTAssertTrue(session.multipartUpload.hasParts)
//        print("parts: \(session.parts.count)")
//        XCTAssertFalse(session.parts.isEmpty)
//        XCTAssertFalse(session.parts.isDone)
//
//        // 2) Send events to complete each part
//        for (index, part) in session.parts.enumerated() {
//            let number = index + 1
//            let taskIdentifier = index + 100
//            if number < session.parts.count {
//                try session.handle(uploadPartEvent: .started(number: number, taskIdentifier: taskIdentifier))
//                try session.handle(uploadPartEvent: .progressUpdated(number: number, bytesTransferred: part.bytes / 2))
//                try session.handle(uploadPartEvent: .completed(number: number))
//            } else {
//                print("Failing part: \(number)")
//                try session.handle(uploadPartEvent: .started(number: number, taskIdentifier: taskIdentifier))
//                try session.handle(uploadPartEvent: .failed(number: number, error: Failure.testFailure))
//            }
//        }
//        XCTAssertTrue(session.parts.isDone)
//        XCTAssertTrue(session.parts.isFailed)
//
//        // 3) Send event to complete multipart upload
//        XCTAssertThrowsError(try session.handle(multipartUploadEvent: .completed(uploadId: uploadId)))
//        XCTAssertFalse(session.multipartUpload.isCompleted)
//        XCTAssertFalse(session.multipartUpload.isAborted)
//    }
//
//    func testSessionWithActiveClient() throws {
//        let client = MockMultipartUploadClient(eventsEnabled: true)
//        var session = StorageMultipartUploadSession(client: client)
//        client.session = session
//
//        let fileURL = URL(string: "/tmp/image.jpg")!
//        let uploadFile = UploadFile(fileURL: fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(250).bytes))
//        let uploadId = UUID().uuidString
//        try session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
//
//    }

}
