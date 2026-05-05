//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Docs: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html

import Amplify
import Foundation

typealias RequestHeaders = [String: String]
typealias RequestParameters = [String: String]

/// Behavior for multipart upload
enum StorageMultipartUploadBehavior {
    /// Immediately creates files for each part and start upload for each one.
    case immediate
    /// Creates files for each part and uses starts uploads progressively.
    case hybrid
    /// Creates files just prior to upload and limits uploads to concurrency limit.
    case progressive
}

// swiftlint:disable type_body_length
class StorageMultipartUploadSession {
    enum Failure: Error {
        case invalidStateTransition
        case partsNotDone
        case partsFailed
        case partsUploadRetryLimitExceeded(underlyingError: Error?)
    }

    private let behavior: StorageMultipartUploadBehavior
    private let fileSystem: FileSystem
    private let logger: Logger

    private let serialQueue = DispatchQueue(label: "com.amazon.aws.amplify.multipartupload-session", target: .global())
    private let id = UUID()
    private var multipartUpload: StorageMultipartUpload
    private let client: StorageMultipartUploadClient
    private let onEvent: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler

    private let transferTask: StorageTransferTask
    private var cancelationError: (any Error)?

    /// If progress does not advance for this many seconds, upload is aborted. 0 = disabled.
    private let progressStallTimeoutSeconds: TimeInterval
    private let stallTimerQueue = DispatchQueue(label: "com.amazon.aws.amplify.storage.multipart.stall-timer")
    private var stallTimerWorkItem: DispatchWorkItem?

    init(
        client: StorageMultipartUploadClient,
        bucket: String,
        key: String,
        contentType: String? = nil,
        requestHeaders: RequestHeaders? = nil,
        onEvent: @escaping AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler,
        behavior: StorageMultipartUploadBehavior = .progressive,
        progressStallTimeoutSeconds: TimeInterval = 0,
        fileSystem: FileSystem = .default,
        logger: Logger = storageLogger
    ) {
        self.client = client
        self.progressStallTimeoutSeconds = progressStallTimeoutSeconds

        let transferType: StorageTransferType = .multiPartUpload(onEvent: onEvent)
        let transferTask = StorageTransferTask(
            transferType: transferType,
            bucket: bucket,
            key: key,
            contentType: contentType,
            requestHeaders: requestHeaders,
            progressStallTimeoutSeconds: progressStallTimeoutSeconds
        )
        self.transferTask = transferTask
        self.onEvent = onEvent

        self.behavior = behavior
        self.fileSystem = fileSystem
        self.logger = logger

        self.multipartUpload = .none
        self.client.integrate(session: self)

        // attach session to transferTask
        transferTask.proxyStorageTask = self

        logger.info("Concurrency Limit is \(concurrentLimit) [based on active processors]")
    }

    init?(
        client: StorageMultipartUploadClient,
        transferTask: StorageTransferTask,
        multipartUpload: StorageMultipartUpload,
        behavior: StorageMultipartUploadBehavior = .progressive,
        progressStallTimeoutSeconds: TimeInterval = 0,
        fileSystem: FileSystem = .default,
        logger: Logger = storageLogger
    ) {
        guard case let .multiPartUpload(onEvent) = transferTask.transferType else {
            return nil
        }

        self.client = client
        self.transferTask = transferTask
        self.multipartUpload = multipartUpload
        self.onEvent = onEvent
        self.progressStallTimeoutSeconds = progressStallTimeoutSeconds

        self.behavior = behavior
        self.fileSystem = fileSystem
        self.logger = logger
    }

    func restart() {
        let snapshot = serialQueue.sync { multipartUpload }
        guard let uploadFile = snapshot.uploadFile,
              let uploadId = snapshot.uploadId,
              let partSize = snapshot.partSize,
              let parts = snapshot.parts
        else {
            return
        }
        uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
    }

    func createSubTask(partNumber: PartNumber) -> StorageTransferTask {
        guard let uploadId = (serialQueue.sync { multipartUpload.uploadId }) else {
            fatalError()
        }
        let transferType: StorageTransferType = .multiPartUploadPart(uploadId: uploadId, partNumber: partNumber)
        let subTask = StorageTransferTask(transferType: transferType, bucket: transferTask.bucket, key: transferTask.key)
        return subTask
    }

    /// Limit to number of concurrent transfers based on active processor count
    var concurrentLimit: Int {
        ProcessInfo.processInfo.activeProcessorCount * 2
    }

    var uploadId: UploadID? {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.uploadId
        }
    }

    var completedParts: StorageUploadParts? {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.parts?.completed
        }
    }

    var partsCount: Int {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            guard let parts = multipartUpload.parts else {
                return 0
            }

            let result = parts.count
            return result
        }
    }

    var partsCompleted: Bool {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.partsCompleted
        }
    }

    var partsFailed: Bool {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.partsFailed
        }
    }

    var inProgressCount: Int {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            guard let parts = multipartUpload.parts else {
                return 0
            }

            let result = parts.inProgress.count
            return result
        }
    }

    var isPaused: Bool {
        serialQueue.sync { multipartUpload.isPaused }
    }

    var isAborted: Bool {
        serialQueue.sync { multipartUpload.isAborted }
    }

    var isCompleted: Bool {
        serialQueue.sync { multipartUpload.isCompleted }
    }

    func part(for number: PartNumber) -> StorageUploadPart? {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.part(for: number)
        }
    }

    func getPendingPartNumbers() -> [Int] {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.pendingPartNumbers
        }
    }

    func startUpload() {
        do {
            let reference = StorageTaskReference(transferTask)
            onEvent(.initiated(reference))
            resetProgressStallTimer()
            logger.debug("Creating Multipart Upload")
            try client.createMultipartUpload()
        } catch {
            fail(error: error)
        }
    }

    private func resetProgressStallTimer() {
        guard progressStallTimeoutSeconds > 0 else { return }
        stallTimerQueue.async { [weak self] in
            guard let self else { return }
            stallTimerWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.fireProgressStallTimeout()
            }
            stallTimerWorkItem = workItem
            stallTimerQueue.asyncAfter(deadline: .now() + progressStallTimeoutSeconds, execute: workItem)
        }
    }

    private func cancelProgressStallTimer() {
        stallTimerQueue.async { [weak self] in
            self?.stallTimerWorkItem?.cancel()
            self?.stallTimerWorkItem = nil
        }
    }

    private func fireProgressStallTimeout() {
        stallTimerQueue.async { [weak self] in
            self?.stallTimerWorkItem = nil
        }
        handle(multipartUploadEvent: .aborting(error: StorageError.unknown("Upload cancelled due to progress stall timeout.", nil)))
        logger.debug("Multipart upload cancelled due to progress stall timeout")
    }

    func fail(error: Error) {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        logger.debug("Multipart Upload Failure: \(error)")
        serialQueue.sync {
            logger.debug("Multipart Upload: \(multipartUpload)")
            multipartUpload.fail(error: error)
        }
        onEvent(.failed(StorageError(error: error)))
    }

    func handle(multipartUploadEvent: StorageMultipartUploadEvent) {
        logger.debug("\(#function): \(multipartUploadEvent)")

        do {
            // Capture pre-transition flag and post-transition state under the
            // serial queue so we never read `multipartUpload` outside the lock.
            // Subsequent branching operates on the captured snapshot.
            let (wasPaused, snapshot): (Bool, StorageMultipartUpload) = try serialQueue.sync {
                let wasPaused = multipartUpload.isPaused
                try multipartUpload.transition(multipartUploadEvent: multipartUploadEvent)
                transferTask.multipartUpload = multipartUpload
                return (wasPaused, multipartUpload)
            }

            switch snapshot {
            case .parts(let uploadId, let uploadFile, let partSize, let parts):
                if wasPaused {
                    logger.debug("Resuming after being paused")
                }
                transferTask.uploadId = uploadId
                resetProgressStallTimer()
                uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
            case .paused(_, _, _, let parts):
                cancelProgressStallTimer()
                cancelInProgressParts(parts: parts)
                if !wasPaused {
                    transferTask.notify(progress: parts.progress)
                }
            case .completed:
                cancelProgressStallTimer()
                onEvent(.completed(()))
            case .aborting(let uploadId, let error):
                cancelationError = error
                cancelProgressStallTimer()
                try client.abortMultipartUpload(uploadId: uploadId)
            case .aborted(_, let error):
                onEvent(.failed(StorageError.unknown("Unable to upload", cancelationError ?? error)))
            case .failed(_, _, let error):
                cancelProgressStallTimer()
                onEvent(.failed(StorageError(error: error)))
            default:
                break
            }
            logger.verbose("MultipartUpload State: \(snapshot)")
        } catch {
            fail(error: error)
        }

    }

    func handle(uploadPartEvent: StorageUploadPartEvent) {
        logger.debug("\(#function): \(uploadPartEvent)")

        do {
            // Capture post-transition state under the serial queue. A sentinel
            // `nil` result means the pre-transition state was .failed/.paused
            // and we should drop the event. All subsequent branching operates
            // on the local snapshot, never on `self.multipartUpload`.
            let snapshot: StorageMultipartUpload? = try serialQueue.sync {
                if case .failed = multipartUpload {
                    logger.debug("Multipart Upload is failed and event cannot be handled: \(uploadPartEvent)")
                    return nil
                }
                if case .paused = multipartUpload {
                    logger.debug("Multipart Upload is paused and event cannot be handled: \(uploadPartEvent)")
                    return nil
                }
                try multipartUpload.transition(uploadPartEvent: uploadPartEvent)
                transferTask.multipartUpload = multipartUpload
                return multipartUpload
            }

            guard let snapshot else { return }

            switch uploadPartEvent {
            case .progressUpdated, .completed:
                resetProgressStallTimer()
            default:
                break
            }

            if uploadPartEvent.isCompleted,
               case .parts(_, _, _, let parts) = snapshot {
                let progress = Progress.discreteProgress(totalUnitCount: Int64(parts.totalBytes))
                progress.completedUnitCount = Int64(parts.bytesTransferred)
                onEvent(.inProcess(progress))
            }

            if case .queued = uploadPartEvent {
                return
            }
            if case .paused = snapshot {
                logger.debug("Multipart Upload is paused and part cannot be completed")
                return
            }

            if uploadPartEvent.isCompleted && snapshot.hasPendingParts {
                guard case .parts(let uploadId, let uploadFile, let partSize, let parts) = snapshot else {
                    throw Failure.invalidStateTransition
                }
                uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
            } else if snapshot.partsCompleted {
                try snapshot.validateForCompletion()
                guard let uploadId = snapshot.uploadId else {
                    throw Failure.invalidStateTransition
                }
                try client.completeMultipartUpload(uploadId: uploadId)
            } else if case .failed(let partNumber, let error) = uploadPartEvent {
                retryPartUpload(partNumber: partNumber, error: error)
            }
        } catch {
            fail(error: error)
        }
    }

    private func retryPartUpload(partNumber: PartNumber, error: Error) {
        do {
            guard transferTask.isBelowRetryLimit else {
                throw Failure.partsUploadRetryLimitExceeded(underlyingError: error)
            }
            // increment retry count and move upload part back to pending
            transferTask.incrementRetryCount()

            // Mutate state under the serial queue and capture what the
            // post-lock side effect needs. A nil result means state no longer
            // matches .parts (e.g. a concurrent cancel swapped it) so there is
            // nothing to retry; the abort path will run via the next event.
            let retryInputs: (StorageMultipartUpload, Bool)? = try serialQueue.sync {
                guard case .parts(let uploadId, let uploadFile, let partSize, var parts) = multipartUpload else {
                    return nil
                }
                let part = try parts.find(partNumber: partNumber)
                let index = partNumber - 1
                parts[index] = .pending(bytes: part.bytes)
                multipartUpload = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
                let noneInProgress = parts.filter { $0.inProgress }.isEmpty
                return (multipartUpload, noneInProgress)
            }

            guard let (snapshot, shouldReupload) = retryInputs, shouldReupload else { return }
            try client.uploadPart(partNumber: partNumber, multipartUpload: snapshot, subTask: createSubTask(partNumber: partNumber))
        } catch {
            handle(multipartUploadEvent: .aborting(error: error))
        }
    }

    private func cancelInProgressParts(parts: StorageUploadParts) {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        serialQueue.sync {
            guard let uploadId = multipartUpload.uploadId,
                  let uploadFile = multipartUpload.uploadFile,
                    let partSize = multipartUpload.partSize
            else {
                logger.warn("Unable to get required values to cancel in progress parts: \(multipartUpload)")
                return
            }

            // collect TaskIdentifier from each part that is in progress
            let cancellingParts: [TaskIdentifier?] = parts.reduce(into: []) { result, part in
                if case .inProgress(_, _, let taskIdentifier) = part {
                    result.append(taskIdentifier)
                } else {
                    result.append(nil)
                }
            }

            for index in 0 ..< cancellingParts.count {
                if cancellingParts[index] != nil {
                    let partNumber = index + 1
                    logger.debug("Pausing upload and cancelling URLSession upload task: partNumber = \(partNumber)")
                }
            }

            // update parts to be paused
            let pausedParts: StorageUploadParts = parts.map { part in
                if case .inProgress = part {
                    return StorageUploadPart.pending(bytes: part.bytes)
                } else {
                    return part
                }
            }
            multipartUpload = .paused(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: pausedParts)

            let taskIdentifiers = cancellingParts.compactMap { $0 }
            logger.debug("Cancelling upload tasks which are in process while paused: \(taskIdentifiers)")

            // block while cancelling upload tasks
            let group = DispatchGroup()
            group.enter()
            client.cancelUploadTasks(taskIdentifiers: taskIdentifiers) {
                group.leave()
            }
            group.wait()
        }
    }

    private func uploadParts(uploadFile: UploadFile, uploadId: UploadID, partSize: StorageUploadPartSize, parts: StorageUploadParts) {
        logger.debug(#function)

        guard inProgressCount < concurrentLimit else {
            logger.debug("Over concurrent limit, skipping...")
            return
        }

        do {
            let pendingPartNumbers = getPendingPartNumbers()
            logger.debug("Pending parts: \(pendingPartNumbers)")
            if pendingPartNumbers.isEmpty {
                return
            }
            let maxPartsCount = min(concurrentLimit, concurrentLimit - inProgressCount)
            if maxPartsCount > 0 {
                let end = min(maxPartsCount, pendingPartNumbers.count)
                let numbers = pendingPartNumbers[0 ..< end]
                // queue upload part first
                for partNumber in numbers {
                    logger.debug("Queuing part \(partNumber)")
                    handle(uploadPartEvent: .queued(partNumber: partNumber))
                }

                // then start upload
                for partNumber in numbers {
                    guard !isAborted else { return }
                    let snapshot = serialQueue.sync { multipartUpload }
                    logger.debug("Multipart Upload: \(snapshot)")
                    // the next call does async work
                    let subTask = createSubTask(partNumber: partNumber)
                    logger.debug("Uploading part: \(partNumber)")
                    try client.uploadPart(partNumber: partNumber, multipartUpload: snapshot, subTask: subTask)
                }
            }
        } catch {
            fail(error: error)
        }
    }

}

extension StorageMultipartUploadSession: Equatable {
    static func == (lhs: StorageMultipartUploadSession, rhs: StorageMultipartUploadSession) -> Bool {
        lhs.id == rhs.id
    }
}

extension StorageMultipartUploadSession: StorageTask {

    func pause() {
        handle(multipartUploadEvent: .pausing)
    }

    func resume() {
        handle(multipartUploadEvent: .resuming)
    }

    func cancel() {
        handle(multipartUploadEvent: .aborting(error: nil))
    }

}
