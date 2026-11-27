//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `completeMultipartUploadDelay` reports completion from a global queue; the counters are lock-guarded.
class MockMultipartUploadClient: StorageMultipartUploadClient, @unchecked Sendable {

    enum Failure: Error {
        case sessionNotIntegrated
        case mockFailure
    }

    private let counterLock = NSLock()
    var uploadPartCount = 0
    var completeMultipartUploadCount = 0
    var abortMultipartUploadCount = 0
    var errorCount = 0
    var taskIdentifier = 100

    private func increment(_ keyPath: ReferenceWritableKeyPath<MockMultipartUploadClient, Int>) {
        counterLock.lock()
        defer { counterLock.unlock() }
        self[keyPath: keyPath] += 1
    }

    let uploadFile: UploadFile
    var session: StorageMultipartUploadSession?

    var didCreate: ((StorageMultipartUploadSession) -> Void)?
    var didStartPartUpload: ((StorageMultipartUploadSession, PartNumber) -> Void)?
    var didTransferBytesForPartUpload: ((StorageMultipartUploadSession, PartNumber, UInt64) -> Void)?
    var shouldFailPartUpload: ((StorageMultipartUploadSession, PartNumber) -> Bool)?
    /// When true, uploadPart only reports started but never progress/completed (for stall timeout testing).
    /// Lock-guarded: tests clear it from another queue while parts are starting.
    var shouldStallPartUpload: Bool {
        get { withLock { stallPartUpload } }
        set { withLock { stallPartUpload = newValue } }
    }
    private var stallPartUpload = false
    /// Parts that started and have not been reported completed by this mock, with their task identifiers.
    private var stalledParts: [PartNumber: TaskIdentifier] = [:]
    /// Delays the `.completed` event from `completeMultipartUpload`, simulating a slow request.
    var completeMultipartUploadDelay: TimeInterval = 0
    /// Overrides the eTag a completed part reports. An empty eTag fails `validateForCompletion()`.
    var eTagForPart: ((PartNumber) -> String)?
    var didCompletePartUpload: ((StorageMultipartUploadSession, PartNumber, String, TaskIdentifier) -> Void)?
    var didFailPartUpload: ((StorageMultipartUploadSession, PartNumber, Error) -> Void)?
    var didCompleteMultipartUpload: ((StorageMultipartUploadSession, UploadID) -> Void)?
    var didAbortMultipartUpload: ((StorageMultipartUploadSession, UploadID) -> Void)?

    init(uploadFile: UploadFile? = nil) {
        self.uploadFile = uploadFile ?? UploadFile(fileURL: URL(fileURLWithPath: "/tmp/upload.txt"), temporaryFileCreated: true, size: UInt64(Bytes.megabytes(42).bytes))
    }

    func integrate(session: StorageMultipartUploadSession) {
        self.session = session
    }

    func createMultipartUpload() throws {
        guard let session else { throw Failure.sessionNotIntegrated }

        let uploadId = UUID().uuidString
        session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
        didCreate?(session)
    }

    func uploadPart(partNumber: PartNumber, multipartUpload: StorageMultipartUpload, subTask: StorageTransferTask) throws {
        guard let _ = multipartUpload.uploadFile,
              let _ = multipartUpload.uploadId,
              let _ = multipartUpload.partSize,
              let part = multipartUpload.part(for: partNumber) else {
                  fatalError()
              }
        print("Upload Part \(partNumber)")
        guard let session else { throw Failure.sessionNotIntegrated }

        increment(\.uploadPartCount)

        defer {
            increment(\.taskIdentifier)
        }

        subTask.sessionTask = MockStorageSessionTask(taskIdentifier: taskIdentifier, state: .suspended)
        session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: taskIdentifier))
        didStartPartUpload?(session, partNumber)

        guard !shouldStallPartUpload else {
            withLock { stalledParts[partNumber] = taskIdentifier }
            return
        }

        let bytesTransferred = part.bytes / 2
        session.handle(uploadPartEvent: .progressUpdated(partNumber: partNumber, bytesTransferred: bytesTransferred, taskIdentifier: taskIdentifier))
        didTransferBytesForPartUpload?(session, partNumber, bytesTransferred)

        if shouldFailPartUpload?(session, partNumber) ?? false {
            session.handle(uploadPartEvent: .failed(partNumber: partNumber, error: Failure.mockFailure))
            return
        }

        if let part = session.part(for: partNumber) {
            if part.inProgress {
                let eTag = eTagForPart?(partNumber) ?? UUID().uuidString
                session.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: taskIdentifier))
                didCompletePartUpload?(session, partNumber, eTag, taskIdentifier)
            }
        }
    }

    func completeMultipartUpload(uploadId: UploadID) throws {
        guard let session else { throw Failure.sessionNotIntegrated }

        increment(\.completeMultipartUploadCount)

        guard completeMultipartUploadDelay > 0 else {
            session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
            didCompleteMultipartUpload?(session, uploadId)
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + completeMultipartUploadDelay) {
            session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
            self.didCompleteMultipartUpload?(session, uploadId)
        }
    }

    func abortMultipartUpload(uploadId: UploadID, error: Error?) throws {
        guard let session else { throw Failure.sessionNotIntegrated }

        increment(\.abortMultipartUploadCount)
        session.handle(multipartUploadEvent: .aborted(uploadId: uploadId, error: error))
        didAbortMultipartUpload?(session, uploadId)
    }

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier], done: @escaping () -> Void) {
        print("Canceling upload tasks")
        withLock { stalledParts = stalledParts.filter { !taskIdentifiers.contains($0.value) } }
        done()
    }

    /// Reports `.completed` for every part that stalled. Parts this starts afterwards follow the
    /// stall flags, so clear them first to let the rest of the upload finish.
    func completeStalledParts() {
        guard let session else { return }
        let parts = withLock {
            let parts = stalledParts.sorted { $0.key < $1.key }
            stalledParts = [:]
            return parts
        }
        for (partNumber, taskIdentifier) in parts {
            let eTag = eTagForPart?(partNumber) ?? UUID().uuidString
            session.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: taskIdentifier))
        }
    }

    /// Reports one `.progressUpdated` for every part that stalled.
    func reportProgressForStalledParts(bytesTransferred: UInt64) {
        guard let session else { return }
        let parts = withLock { stalledParts.sorted { $0.key < $1.key } }
        for (partNumber, taskIdentifier) in parts {
            session.handle(uploadPartEvent: .progressUpdated(
                partNumber: partNumber,
                bytesTransferred: bytesTransferred,
                taskIdentifier: taskIdentifier
            ))
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        counterLock.lock()
        defer { counterLock.unlock() }
        return body()
    }

}
