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
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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

    func testCompletedMultipartUploadSession() throws {
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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

    func testAbortedMultipartUploadSession() throws {
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        var closureSession: StorageMultipartUploadSession?
        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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
        client.didCompletePartUpload = { (_, partNumber, _, _) in
            if partNumber == 5 {
                closureSession?.handle(multipartUploadEvent: .aborting(error: nil))
                XCTAssertTrue(closureSession?.isAborted ?? false)
            }

        }
        let session = StorageMultipartUploadSession(client: client, bucket: bucket, key: key, onEvent: onEvent)
        closureSession = session

        session.startUpload()

        wait(for: [initiatedExp, completedExp], timeout: 300.0)

        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertTrue(session.isAborted)

        XCTAssertEqual(client.completeMultipartUploadCount, 0)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
        XCTAssertEqual(client.errorCount, 0)
        XCTAssertGreaterThan(client.uploadPartCount, 0)
        closureSession = nil
    }

    func testPauseAndResumeMultipartUploadSession() throws {
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        var closureSession: StorageMultipartUploadSession?
        var pauseCount = 0
        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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
        client.didTransferBytesForPartUpload = { (_, partNumber, bytesTransferred) in
            if pauseCount == 0, partNumber > 5, bytesTransferred > 0 {
                print("pausing on \(partNumber)")
                pauseCount += 1
                closureSession?.handle(multipartUploadEvent: .pausing)
                XCTAssertTrue(closureSession?.isPaused ?? false)
                print("resuming on \(partNumber)")
                closureSession?.handle(multipartUploadEvent: .resuming)
                XCTAssertFalse(closureSession?.isPaused ?? true)
            }
        }

        let session = StorageMultipartUploadSession(client: client, bucket: bucket, key: key, onEvent: onEvent)
        closureSession = session

        session.startUpload()

        wait(for: [initiatedExp, completedExp], timeout: 300.0)

        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertTrue(session.isCompleted)

        XCTAssertEqual(client.completeMultipartUploadCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.errorCount, 0)
        XCTAssertGreaterThan(client.uploadPartCount, 0)
        closureSession = nil
    }

    func testPartUploadFailedOnce() throws {
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        var failCount = 0
        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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
        client.shouldFailPartUpload = { _, partNumber in
            if failCount == 0, partNumber == 5 {
                print("failing on \(partNumber)")
                failCount += 1
                return true
            } else {
                return false
            }
        }

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

    func testPartUploadFailedOverLimit() throws {
        throw XCTSkip("Temporarily disabling test which only fails on GitHub CI/CD")
        let initiatedExp = expectation(description: "Initiated")
        let completedExp = expectation(description: "Completed")

        var failCount = 0
        let bucket = "my-bucket"
        let key = "key.txt"
        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
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
        client.shouldFailPartUpload = { _, partNumber in
            if partNumber == 5 {
                print("failing on \(partNumber)")
                failCount += 1
                return true
            } else {
                return false
            }
        }

        let session = StorageMultipartUploadSession(client: client, bucket: bucket, key: key, onEvent: onEvent)

        session.startUpload()

        wait(for: [initiatedExp, completedExp], timeout: 300.0)

        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertTrue(session.isAborted)

        XCTAssertEqual(client.completeMultipartUploadCount, 0)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
        XCTAssertEqual(client.errorCount, 0)
        XCTAssertGreaterThan(client.uploadPartCount, 0)
    }

    // MARK: - Private -

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

}
