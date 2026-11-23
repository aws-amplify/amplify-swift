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

// MARK: - Progress stall timer: observation window

/// A clock for the stall timer that can jump forward, to make a fire look late without waiting, and
/// that tells the test about each read.
///
/// The session reads the clock once when it arms the timer, and once in each fire, after that fire
/// checked that no part event was handled since its arm. With an interval longer than the observation
/// window the reads are: 1 arm (waiting), 2 fire, 3 arm (observing), 4 fire.
private final class StallTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var offsetNanoseconds: UInt64 = 0
    private var reads = 0
    private var readHandler: (@Sendable (Int) -> Void)?

    /// `handler` runs before each read returns, with the number of the read, starting at 1.
    func onRead(_ handler: @escaping @Sendable (Int) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        readHandler = handler
    }

    var readCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return reads
    }

    func now() -> DispatchTime {
        lock.lock()
        reads += 1
        let read = reads
        let handler = readHandler
        lock.unlock()
        handler?(read)
        lock.lock()
        defer { lock.unlock() }
        return DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + offsetNanoseconds)
    }

    func advance(seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        offsetNanoseconds += UInt64(seconds * 1_000_000_000)
    }
}

/// Records what the upload reported, with times, without fulfilling an expectation twice.
private final class StallEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var stallFailureCount = 0
    private(set) var otherFailureCount = 0
    private(set) var completedCount = 0
    private(set) var firstStallFailureAt: DispatchTime?
    let stallFailed: XCTestExpectation
    let completed: XCTestExpectation

    init(stallFailed: XCTestExpectation, completed: XCTestExpectation) {
        self.stallFailed = stallFailed
        self.completed = completed
    }

    var onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler {
        { [self] event in
            switch event {
            case .initiated, .inProcess:
                break
            case .failed(let error):
                lock.lock()
                let isStall: Bool
                if case .unknown(_, let underlying) = error,
                   let stall = underlying as? StorageError,
                   case .unknown(let message, _) = stall,
                   message == "Upload cancelled due to progress stall timeout." {
                    isStall = true
                } else {
                    isStall = false
                }
                if isStall {
                    stallFailureCount += 1
                    if firstStallFailureAt == nil {
                        firstStallFailureAt = .now()
                    }
                } else {
                    otherFailureCount += 1
                }
                let fulfill = isStall && stallFailureCount == 1
                lock.unlock()
                if fulfill {
                    stallFailed.fulfill()
                }
            case .completed:
                lock.lock()
                completedCount += 1
                let fulfill = completedCount == 1
                lock.unlock()
                if fulfill {
                    completed.fulfill()
                }
            }
        }
    }
}

private func seconds(from start: DispatchTime, to end: DispatchTime?) -> TimeInterval {
    guard let end else { return -1 }
    return TimeInterval(Int64(bitPattern: end.uptimeNanoseconds &- start.uptimeNanoseconds)) / 1_000_000_000
}

extension StorageMultipartUploadSessionTests {

    private func makeRecorder(expectStall: Bool, expectCompletion: Bool) -> StallEventRecorder {
        let stallFailed = expectation(description: "Failed with stall error")
        stallFailed.isInverted = !expectStall
        let completed = expectation(description: "Completed")
        completed.isInverted = !expectCompletion
        return StallEventRecorder(stallFailed: stallFailed, completed: completed)
    }

    private func makeStallSession(
        client: MockMultipartUploadClient,
        recorder: StallEventRecorder,
        stallInterval: TimeInterval,
        observationWindow: TimeInterval,
        clock: StallTestClock = StallTestClock()
    ) -> StorageMultipartUploadSession {
        StorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: recorder.onEvent,
            progressStallTimeoutSeconds: stallInterval,
            stallTimerClock: { clock.now() },
            stallObservationWindowSeconds: observationWindow
        )
    }

    /// Given: parts that started and then send no events, in a process that keeps running
    /// When: the stall interval passes
    /// Then: the upload aborts once, at the interval: the observation window is the last part of the
    ///   interval, not an addition to it
    func testProgressStallTimeout_processKeepsRunning_shouldAbortAtInterval() {
        let stallInterval: TimeInterval = 0.6
        let observationWindow: TimeInterval = 0.2
        let clock = StallTestClock()
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        let recorder = makeRecorder(expectStall: true, expectCompletion: false)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        let start = DispatchTime.now()
        session.startUpload()

        wait(for: [recorder.stallFailed, recorder.completed], timeout: stallInterval + 1.0)
        XCTAssertGreaterThanOrEqual(seconds(from: start, to: recorder.firstStallFailureAt), stallInterval * 0.9)
        // Arm and fire of the waiting part, arm and fire of one observation window.
        XCTAssertEqual(clock.readCount, 4)
        XCTAssertEqual(recorder.stallFailureCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
    }

    /// Given: parts that send no events until the stall timer's first fire, as while the app is
    ///   suspended
    /// When: every in-flight part's `.completed` arrives inside the observation window that the
    ///   fire opened
    /// Then: the upload is not aborted and completes
    func testProgressStallTimeout_partsCompleteInObservationWindow_shouldNotAbort() {
        let stallInterval: TimeInterval = 1.2
        let observationWindow: TimeInterval = 1.0
        let clock = StallTestClock()
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        clock.onRead { [unowned client] read in
            guard read == 2 else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + observationWindow / 3) {
                client.shouldStallPartUpload = false
                client.completeStalledParts()
            }
        }
        let recorder = makeRecorder(expectStall: false, expectCompletion: true)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        session.startUpload()

        wait(for: [recorder.completed], timeout: stallInterval + 1.0)
        wait(for: [recorder.stallFailed], timeout: 0.1)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.completeMultipartUploadCount, 1)
    }

    /// Given: parts that send no events
    /// When: a progress event for every in-flight part is handled while the fire of the waiting part
    ///   is deciding
    /// Then: that fire does not replace the full interval the event armed with the shorter
    ///   observation window; the upload aborts one full interval after the event, exactly once
    func testProgressStallTimeout_eventDuringWaitingFire_shouldKeepFullInterval() {
        let stallInterval: TimeInterval = 1.0
        let observationWindow: TimeInterval = 0.2
        let clock = StallTestClock()
        let eventAt = AtomicValue<DispatchTime?>(initialValue: nil)
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        clock.onRead { [unowned client] read in
            guard read == 2 else { return }
            eventAt.set(.now())
            client.reportProgressForStalledParts(bytesTransferred: 1_000)
        }
        let recorder = makeRecorder(expectStall: true, expectCompletion: false)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        session.startUpload()

        wait(for: [recorder.stallFailed, recorder.completed], timeout: stallInterval * 2 + 1.0)
        guard let event = eventAt.get() else {
            XCTFail("The stall timer never fired")
            return
        }
        XCTAssertGreaterThanOrEqual(seconds(from: event, to: recorder.firstStallFailureAt), stallInterval * 0.9)
        XCTAssertEqual(recorder.stallFailureCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
    }

    /// Given: parts that send no events
    /// When: a progress event for every in-flight part is handled while the fire of the observation
    ///   window is deciding
    /// Then: that fire does not abort, because an event arrived after it was armed; the upload aborts
    ///   one full interval after the event, exactly once
    func testProgressStallTimeout_eventDuringObservingFire_shouldNotAbort() {
        let stallInterval: TimeInterval = 0.6
        let observationWindow: TimeInterval = 0.2
        let clock = StallTestClock()
        let eventAt = AtomicValue<DispatchTime?>(initialValue: nil)
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        clock.onRead { [unowned client] read in
            guard read == 4 else { return }
            eventAt.set(.now())
            client.reportProgressForStalledParts(bytesTransferred: 1_000)
        }
        let recorder = makeRecorder(expectStall: true, expectCompletion: false)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        session.startUpload()

        wait(for: [recorder.stallFailed, recorder.completed], timeout: stallInterval * 2 + 1.0)
        guard let event = eventAt.get() else {
            XCTFail("The observation window never fired")
            return
        }
        XCTAssertGreaterThanOrEqual(seconds(from: event, to: recorder.firstStallFailureAt), stallInterval * 0.9)
        XCTAssertEqual(recorder.stallFailureCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
    }

    /// Given: parts that send no events, and an observation window that is open
    /// When: the process stops inside the window, so the window's fire is late
    /// Then: that fire has seen nothing of the window and opens another one instead of aborting; the
    ///   next fire is on time and aborts, exactly once
    func testProgressStallTimeout_lateObservingFire_shouldOpenAnotherWindow() {
        let stallInterval: TimeInterval = 0.6
        let observationWindow: TimeInterval = 0.4
        let clock = StallTestClock()
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        clock.onRead { [unowned clock] read in
            // The first fire of the window finds the clock 300 s past its deadline.
            guard read == 4 else { return }
            clock.advance(seconds: 300)
        }
        let recorder = makeRecorder(expectStall: true, expectCompletion: false)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        let start = DispatchTime.now()
        session.startUpload()

        wait(for: [recorder.stallFailed, recorder.completed], timeout: stallInterval + observationWindow + 1.0)
        XCTAssertGreaterThanOrEqual(
            seconds(from: start, to: recorder.firstStallFailureAt),
            (stallInterval + observationWindow) * 0.9
        )
        // Waiting part, the late window, and the second window: an arm and a fire each.
        XCTAssertEqual(clock.readCount, 6)
        XCTAssertEqual(recorder.stallFailureCount, 1)
        XCTAssertEqual(client.abortMultipartUploadCount, 1)
    }

    /// Given: an observation window that is open
    /// When: the upload is paused inside the window, and later resumed with parts that complete
    /// Then: the paused upload is never aborted, and after resume it completes
    func testProgressStallTimeout_pauseDuringObservationWindow_shouldNotAbort() {
        let stallInterval: TimeInterval = 1.2
        let observationWindow: TimeInterval = 1.0
        let clock = StallTestClock()
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        let paused = expectation(description: "Paused")
        clock.onRead { [unowned client] read in
            guard read == 2 else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + observationWindow / 3) {
                client.session?.pause()
                paused.fulfill()
            }
        }
        let recorder = makeRecorder(expectStall: false, expectCompletion: true)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        session.startUpload()
        wait(for: [paused], timeout: stallInterval + 1.0)
        // Hold the pause well past the observation window: nothing may fire.
        Thread.sleep(forTimeInterval: observationWindow * 1.5)
        XCTAssertTrue(session.isPaused)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)

        client.shouldStallPartUpload = false
        session.resume()

        wait(for: [recorder.completed], timeout: 1.0)
        wait(for: [recorder.stallFailed], timeout: 0.1)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
    }

    /// Given: an observation window that is open, and a CompleteMultipartUpload that takes longer
    ///   than the window
    /// When: every part completes inside the window, so completion is in flight when it ends
    /// Then: the upload completes and is never aborted
    func testProgressStallTimeout_completionInFlightWhenWindowEnds_shouldNotAbort() {
        let stallInterval: TimeInterval = 1.2
        let observationWindow: TimeInterval = 1.0
        let clock = StallTestClock()
        let client = MockMultipartUploadClient()
        client.shouldStallPartUpload = true
        client.completeMultipartUploadDelay = observationWindow * 1.5
        clock.onRead { [unowned client] read in
            guard read == 2 else { return }
            DispatchQueue.global().asyncAfter(deadline: .now() + observationWindow / 3) {
                client.shouldStallPartUpload = false
                client.completeStalledParts()
            }
        }
        let recorder = makeRecorder(expectStall: false, expectCompletion: true)
        let session = makeStallSession(
            client: client,
            recorder: recorder,
            stallInterval: stallInterval,
            observationWindow: observationWindow,
            clock: clock
        )

        session.startUpload()

        wait(for: [recorder.completed], timeout: stallInterval + client.completeMultipartUploadDelay + 1.0)
        wait(for: [recorder.stallFailed], timeout: 0.1)
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(client.abortMultipartUploadCount, 0)
        XCTAssertEqual(client.completeMultipartUploadCount, 1)
    }
}
