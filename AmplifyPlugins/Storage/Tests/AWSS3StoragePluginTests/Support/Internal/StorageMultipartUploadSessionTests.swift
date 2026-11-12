//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class StorageMultipartUploadSessionTests: XCTestCase, @unchecked Sendable {
    enum Failure: Error {
        case unableToCreateData
        case testFailure
    }

    /// Given: A StorageMultipartUploadSession with progressStallTimeoutInterval and a client that stalls (no progress)
    /// When: startUpload is invoked
    /// Then: After the interval, .failed event is received with progress stall timeout error
    func testProgressStallTimeoutWhenNoProgressFailsWithStallError() throws {
        let stallInterval: TimeInterval = 0.05
        let failedExp = expectation(description: "Failed with stall error")

        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true

        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated:
                break
            case .inProcess:
                break
            case .failed(let error):
                if case .unknown(let outer, let underlying) = error,
                   outer == "Unable to upload",
                   let stall = underlying as? StorageError,
                   case .unknown(let stallMessage, _) = stall,
                   stallMessage == "Upload cancelled due to progress stall timeout." {
                    failedExp.fulfill()
                }
            case .completed:
                XCTFail("Should not complete when stalling")
            }
        }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: onEvent,
            progressStallTimeoutSeconds: stallInterval
        )
        session.startUpload()

        wait(for: [failedExp], timeout: stallInterval + 0.5)
        XCTAssertTrue(session.isAborted)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
    }

    /// Given: A StorageMultipartUploadSession with a progress stall timeout, whose parts all upload
    ///   successfully and whose CompleteMultipartUpload takes longer than the stall interval
    /// When: the final part completes and completion is in flight
    /// Then: the upload completes and is never aborted — the stall timer must not be armed across
    ///   CompleteMultipartUpload, because no progress event can arrive to reset it
    func testProgressStallTimeoutDoesNotAbortWhileCompletionIsInFlight() throws {
        let stallInterval: TimeInterval = 0.1
        let completedExp = expectation(description: "Completed")

        let client = MockMultipartUploadClient()
        client.completeMultipartUploadDelay = stallInterval * 3

        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated, .inProcess:
                break
            case .failed(let error):
                XCTFail("Must not fail while completion is in flight: \(error)")
            case .completed:
                completedExp.fulfill()
            }
        }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: onEvent,
            progressStallTimeoutSeconds: stallInterval
        )
        session.startUpload()

        wait(for: [completedExp], timeout: client.completeMultipartUploadDelay + 1.0)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.completeMultipartUploadCount, 1)
    }

    /// Given: A session whose CompleteMultipartUpload takes longer than the stall interval, paused
    ///   and resumed once every part is done
    /// When: `resume()` re-arms the timer through the `.parts` case, where `uploadParts` finds
    ///   nothing pending, so nothing cancels it again before completion returns
    /// Then: the upload completes and is never aborted -- cancelling at the completion call site is
    ///   not enough on its own, `fireProgressStallTimeout`'s state guard is what closes this one
    func testProgressStallTimeoutDoesNotAbortAfterPauseResumeDuringCompletion() throws {
        let stallInterval: TimeInterval = 0.1
        let completedExp = expectation(description: "Completed")

        let client = MockMultipartUploadClient()
        client.completeMultipartUploadDelay = stallInterval * 3
        client.didCompletePartUpload = { session, _, _, _ in
            guard session.partsCompleted else { return }
            session.pause()
            session.resume()
        }

        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated, .inProcess:
                break
            case .failed(let error):
                XCTFail("Must not fail after pause/resume while completion is in flight: \(error)")
            case .completed:
                completedExp.fulfill()
            }
        }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: onEvent,
            progressStallTimeoutSeconds: stallInterval
        )
        session.startUpload()

        wait(for: [completedExp], timeout: client.completeMultipartUploadDelay + 1.0)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.completeMultipartUploadCount, 1)
    }

    /// Given: A session whose parts report an empty eTag, so `validateForCompletion()` fails once
    ///   every part is done, while the stall timer is still armed
    /// When: validation fails and the stall deadline then elapses
    /// Then: the caller is told `.failed` exactly once and no AbortMultipartUpload is sent --
    ///   `fireProgressStallTimeout`'s `case .parts` check is what stops the timer firing in
    ///   `.failed`, which would otherwise abort an upload the caller has already been told failed
    func testProgressStallTimeoutDoesNotAbortAfterCompletionValidationFails() throws {
        let stallInterval: TimeInterval = 0.1
        let failedExp = expectation(description: "Failed exactly once")
        let notAbortedExp = expectation(description: "Never aborted")
        notAbortedExp.isInverted = true
        // Counted rather than fulfilled twice: without the state guard the abort reports a second
        // `.failed` from the stall-timer queue, and an over-fulfilled expectation raises an uncaught
        // `NSInternalInconsistencyException` there, which aborts the process during a later test.
        // Counting keeps the regression a failure of this test and still pins "exactly once".
        let failedCount = AtomicValue(initialValue: 0)

        let client = MockMultipartUploadClient()
        client.eTagForPart = { _ in "" }
        client.didAbortMultipartUpload = { _, _ in notAbortedExp.fulfill() }

        let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler = { event in
            switch event {
            case .initiated, .inProcess:
                break
            case .failed:
                if failedCount.increment() == 1 {
                    failedExp.fulfill()
                }
            case .completed:
                XCTFail("Must not complete when the parts fail validation")
            }
        }

        let session = StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: onEvent,
            progressStallTimeoutSeconds: stallInterval
        )
        session.startUpload()

        wait(for: [failedExp], timeout: stallInterval + 0.5)
        wait(for: [notAbortedExp], timeout: stallInterval * 4)
        XCTAssertEqual(failedCount.get(), 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.completeMultipartUploadCount, 0)
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

    /// Given: A StorageTransferTask with a valid StorageTransferType
    /// When: A StorageMultipartUploadSession is created from the task
    /// Then: Its values are set correctly
    func testSessionCreation_withTransferTask() throws {
        let client = MockMultipartUploadClient()
        let transferType: StorageTransferType = .multiPartUpload(onEvent: {_ in })
        let transferTask = StorageTransferTask(
            transferType: transferType,
            bucket: "bucket",
            key: "key"
        )

        let session = try XCTUnwrap(StorageMultipartUploadSession(client: client, transferTask: transferTask, multipartUpload: .none, logger: MockLogger()))
        XCTAssertEqual(session.partsCount, 0)
        XCTAssertEqual(session.inProgressCount, 0)
        XCTAssertFalse(session.partsCompleted)
        XCTAssertFalse(session.partsFailed)
    }

    /// Given: A StorageTransferTask with an invalid StorageTransferType
    /// When: A StorageMultipartUploadSession is created from the task
    /// Then: Its values are set correctly
    func testSessionCreation_withTransferTask_andInvalidTransferType_shouldReturnNil() throws {
        let client = MockMultipartUploadClient()
        let transferType: StorageTransferType = .list(onEvent: {_ in })
        let transferTask = StorageTransferTask(
            transferType: transferType,
            bucket: "bucket",
            key: "key"
        )

        XCTAssertNil(StorageMultipartUploadSession(
            client: client,
            transferTask: transferTask,
            multipartUpload: .none
        ))
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
                completedExp.fulfill()
            case .completed:
                print("Completed")
                XCTFail("Must not complete")
                completedExp.fulfill()
            }
        }

        let client = MockMultipartUploadClient() // creates an UploadFile for the mock process
        client.didCompletePartUpload = { _, partNumber, _, _ in
            if partNumber == 5 {
                closureSession?.cancel()
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
        client.didTransferBytesForPartUpload = { _, partNumber, bytesTransferred in
            if pauseCount == 0, partNumber > 5, bytesTransferred > 0 {
                print("pausing on \(partNumber)")
                pauseCount += 1
                closureSession?.pause()
                XCTAssertTrue(closureSession?.isPaused ?? false)
                print("resuming on \(partNumber)")
                closureSession?.resume()
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
        try XCTSkipIf(true, "Temporarily disabling test which only fails on GitHub CI/CD")
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
        let size = Int(minimumPartSize)
        let parts: [String] = [
            Array(repeating: "a", count: size).joined(),
            Array(repeating: "b", count: size).joined(),
            Array(repeating: "c", count: size).joined(),
            Array(repeating: "d", count: size).joined(),
            Array(repeating: "e", count: size).joined(),
            Array(repeating: "f", count: size / 2).joined()
        ]
        let string = parts.joined()

        let data = Data(string.utf8)
        let fileURL = try FileSystem.default.createTemporaryFile(data: data)
        return fileURL
    }

}
