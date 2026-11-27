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
/// - Note: `@unchecked Sendable`: the session's state transitions are serialized by its
///   own queue.
class StorageMultipartUploadSession: @unchecked Sendable {
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
    /// The armed stall timer. Only touched on `stallTimerQueue`.
    private var stallTimer: DispatchSourceTimer?
    /// Clock used to tell an on-time fire from a late one. Same clock as `DispatchTime.now()`.
    private let stallTimerClock: @Sendable () -> DispatchTime
    /// The last part of the stall interval. The upload is only aborted after the process was seen
    /// running for this long without a part event. Never longer than the interval.
    private let stallObservationWindowSeconds: TimeInterval
    /// Incremented for every part event that resets the stall timer. Guarded by `serialQueue`.
    private var partEventGeneration: UInt64 = 0

    /// How far the system may defer the stall timer. Kept well below `lateStallFireThresholdSeconds`, so
    /// that a fire is only late when the process was not running, not because the timer was coalesced.
    private static let stallTimerLeeway: DispatchTimeInterval = .milliseconds(250)
    /// A running process fires within `stallTimerLeeway` of the deadline, so a fire this much later means
    /// the process was not running at the deadline.
    private static let lateStallFireThresholdSeconds: TimeInterval = 1
    /// Upper bound of the observation window: long enough for the URLSession events that were queued
    /// while the process was not running to be delivered, short compared with a stall interval.
    static let maximumStallObservationWindowSeconds: TimeInterval = 10

    /// What the stall timer knew when it was armed.
    private struct StallTimerArm {
        enum Phase: String {
            /// The first part of the interval. Its fire only opens the observation window.
            case waiting
            /// The observation window. Its fire aborts the upload, unless it is late.
            case observing
        }

        let phase: Phase
        let deadline: DispatchTime
        let generation: UInt64
    }

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
        logger: Logger = storageLogger,
        stallTimerClock: @escaping @Sendable () -> DispatchTime = { .now() },
        stallObservationWindowSeconds: TimeInterval = StorageMultipartUploadSession.maximumStallObservationWindowSeconds
    ) {
        self.client = client
        self.progressStallTimeoutSeconds = progressStallTimeoutSeconds
        self.stallTimerClock = stallTimerClock
        self.stallObservationWindowSeconds = min(stallObservationWindowSeconds, progressStallTimeoutSeconds)

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
        logger: Logger = storageLogger,
        stallTimerClock: @escaping @Sendable () -> DispatchTime = { .now() },
        stallObservationWindowSeconds: TimeInterval = StorageMultipartUploadSession.maximumStallObservationWindowSeconds
    ) {
        guard case let .multiPartUpload(onEvent) = transferTask.transferType else {
            return nil
        }

        self.client = client
        self.transferTask = transferTask
        self.multipartUpload = multipartUpload
        self.onEvent = onEvent
        self.progressStallTimeoutSeconds = progressStallTimeoutSeconds
        self.stallTimerClock = stallTimerClock
        self.stallObservationWindowSeconds = min(stallObservationWindowSeconds, progressStallTimeoutSeconds)

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
        guard let uploadId = serialQueue.sync(execute: { multipartUpload.uploadId }) else {
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
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.isPaused
        }
    }

    var isAborted: Bool {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.isAborted
        }
    }

    var isCompleted: Bool {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        return serialQueue.sync {
            multipartUpload.isCompleted
        }
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
            logger.debug("Creating Multipart Upload")
            try client.createMultipartUpload()
        } catch {
            fail(error: error)
        }
    }

    /// Arms the stall timer for a full interval, replacing the armed one.
    ///
    /// The interval has two parts: `progressStallTimeoutSeconds - stallObservationWindowSeconds` of
    /// waiting, then the observation window. See `fireProgressStallTimeout(arm:)`.
    private func resetProgressStallTimer() {
        let waiting = progressStallTimeoutSeconds - stallObservationWindowSeconds
        if waiting > 0 {
            armProgressStallTimer(.waiting, after: waiting, continuing: nil)
        } else {
            armProgressStallTimer(.observing, after: stallObservationWindowSeconds, continuing: nil)
        }
    }

    /// - Parameter firedArm: the arm whose fire asks for this one, or nil when a part event or a state
    ///   change resets the timer. A fire only continues its own interval: if a part event was handled
    ///   since `firedArm`, that event has armed, or is about to arm, a full interval, which the shorter
    ///   observation window must not replace.
    private func armProgressStallTimer(_ phase: StallTimerArm.Phase, after seconds: TimeInterval, continuing firedArm: StallTimerArm?) {
        guard progressStallTimeoutSeconds > 0 else { return }
        stallTimerQueue.async { [weak self] in
            guard let self else { return }
            let generation = serialQueue.sync { partEventGeneration }
            if let firedArm, firedArm.generation != generation {
                logger.debug("Progress stall timer: decision=ignore reason=eventDuringFire phase=\(firedArm.phase.rawValue)")
                return
            }
            stallTimer?.cancel()
            let arm = StallTimerArm(phase: phase, deadline: stallTimerClock() + seconds, generation: generation)
            let timer = DispatchSource.makeTimerSource(queue: stallTimerQueue)
            timer.schedule(deadline: .now() + seconds, leeway: Self.stallTimerLeeway)
            timer.setEventHandler { [weak self, weak timer] in
                // A reset or cancel replaces `stallTimer`, so only the armed timer gets past this.
                guard let self, let timer, stallTimer === timer else { return }
                timer.cancel()
                stallTimer = nil
                fireProgressStallTimeout(arm: arm)
            }
            stallTimer = timer
            timer.resume()
        }
    }

    private func cancelProgressStallTimer() {
        stallTimerQueue.async { [weak self] in
            self?.stallTimer?.cancel()
            self?.stallTimer = nil
        }
    }

    /// Runs on `stallTimerQueue` when no part event reset the timer before its deadline.
    ///
    /// "No part event for the interval" is only evidence of a stall if the process was running. Part
    /// events come from the URLSession delegate, which cannot run while the app is suspended, but the
    /// deadline keeps running. When the app is resumed, an overdue timer fires before the queued events
    /// of the parts that moved or finished in the meantime are delivered.
    ///
    /// So the upload is only aborted after the process was seen running through the observation window,
    /// the last part of the interval, without a part event:
    /// - the fire of the waiting part only opens the window, whether it is on time or late;
    /// - a fire of the window that is late means the process stopped inside it, and opens another one;
    /// - a fire of the window that is on time aborts.
    /// A process that keeps running therefore aborts a stalled upload at the interval, as before.
    private func fireProgressStallTimeout(arm: StallTimerArm) {
        // Only a part transfer can stall; ignore a timer that outlived one. A part event handled after
        // the arm has a reset queued behind this fire.
        guard isWatchingParts(since: arm) else { return }

        let lateness = Self.seconds(from: arm.deadline, to: stallTimerClock())
        let detail = "phase=\(arm.phase.rawValue) lateness=\(String(format: "%.1f", lateness))s"

        if arm.phase == .waiting || lateness > Self.lateStallFireThresholdSeconds {
            logger.debug("Progress stall timer: decision=observe window=\(stallObservationWindowSeconds)s \(detail)")
            armProgressStallTimer(.observing, after: stallObservationWindowSeconds, continuing: arm)
            return
        }

        // Abort, unless a part event was handled while this fire was deciding.
        guard isWatchingParts(since: arm) else {
            logger.debug("Progress stall timer: decision=ignore reason=eventDuringFire \(detail)")
            return
        }
        logger.debug("Progress stall timer: decision=abort \(detail)")
        handle(multipartUploadEvent: .aborting(error: StorageError.unknown("Upload cancelled due to progress stall timeout.", nil)))
        logger.debug("Multipart upload cancelled due to progress stall timeout")
    }

    /// Whether parts are still being transferred and no part event was handled since `arm`.
    private func isWatchingParts(since arm: StallTimerArm) -> Bool {
        serialQueue.sync {
            guard case .parts = multipartUpload, !multipartUpload.partsCompleted else { return false }
            return partEventGeneration == arm.generation
        }
    }

    private static func seconds(from start: DispatchTime, to end: DispatchTime) -> TimeInterval {
        guard end.uptimeNanoseconds > start.uptimeNanoseconds else { return 0 }
        return TimeInterval(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
    }

    func fail(error: Error) {
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
            let wasPaused: Bool
            let snapshot: StorageMultipartUpload

            (wasPaused, snapshot) = try serialQueue.sync {
                let wasPaused = multipartUpload.isPaused
                try multipartUpload.transition(multipartUploadEvent: multipartUploadEvent)

                // update the transerTask with every state transition
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
                cancelInProgressParts()
                if !wasPaused {
                    transferTask.notify(progress: parts.progress)
                }
            case .completed:
                cancelProgressStallTimer()
                onEvent(.completed(()))
            case .aborting(_, let error):
                serialQueue.sync { cancelationError = error }
                cancelProgressStallTimer()
                try abort()
            case .aborted(_, let error):
                let cancelationError = serialQueue.sync { self.cancelationError }
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
            // Read state and transition under one lock; nil means the event was dropped (state was .failed/.paused).
            let snapshot: StorageMultipartUpload? = try serialQueue.sync {
                if case .failed = multipartUpload {
                    logger.debug("Multipart Upload is failed and event cannot be handled: \(uploadPartEvent)")
                    return nil
                }
                if case .paused(let uploadId, let uploadFile, let partSize, var parts) = multipartUpload {
                    // A part that finished preparing while paused is not sent (#4407): return it to pending so
                    // resume() starts it again. Its own uploadParts loop has already passed it.
                    let index = uploadPartEvent.number - 1
                    if case .started = uploadPartEvent, parts.indices.contains(index), parts[index].isQueued {
                        parts[index] = .pending(bytes: parts[index].bytes)
                        multipartUpload = .paused(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
                        transferTask.multipartUpload = multipartUpload
                    }
                    logger.debug("Multipart Upload is paused and event cannot be handled: \(uploadPartEvent)")
                    return nil
                }
                try multipartUpload.transition(uploadPartEvent: uploadPartEvent)
                // update the transferTask with every state transition
                transferTask.multipartUpload = multipartUpload
                // The stall timer tells from this whether a part event was handled since it was armed.
                switch uploadPartEvent {
                case .progressUpdated, .completed:
                    partEventGeneration &+= 1
                default:
                    break
                }
                return multipartUpload
            }

            guard let snapshot else { return }

            switch uploadPartEvent {
            case .progressUpdated, .completed:
                resetProgressStallTimer()
            default:
                break
            }

            if uploadPartEvent.isCompleted {
                // report progress
                if case .parts(_, _, _, let parts) = snapshot {
                    let progress = Progress.discreteProgress(totalUnitCount: Int64(parts.totalBytes))
                    progress.completedUnitCount = Int64(parts.bytesTransferred)
                    onEvent(.inProcess(progress))
                }
            }

            let isCompletedEvent = uploadPartEvent.isCompleted

            if case .queued = uploadPartEvent {
                return
            } else if case .paused = snapshot {
                logger.debug("Multipart Upload is paused and part cannot be completed")
                return
            } else if isCompletedEvent && snapshot.hasPendingParts {
                if case .parts(let uploadId, let uploadFile, let partSize, let parts) = snapshot {
                    uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
                } else {
                    throw Failure.invalidStateTransition
                }
            } else if snapshot.partsCompleted {
                do {
                    try snapshot.validateForCompletion()
                } catch {
                    fail(error: error)
                    return
                }

                if let uploadId = snapshot.uploadId {
                    // Every part is done, so nothing can reset the timer while CompleteMultipartUpload runs.
                    cancelProgressStallTimer()
                    try client.completeMultipartUpload(uploadId: uploadId)
                } else {
                    throw Failure.invalidStateTransition
                }
            } else if case .failed(let partNumber, let error) = uploadPartEvent {
                retryPartUpload(partNumber: partNumber, error: error)
            }
        } catch {
            fail(error: error)
        }
    }

    private func retryPartUpload(partNumber: PartNumber, error: Error) {
        do {
            if transferTask.isBelowRetryLimit {
                // increment retry count and move upload part back to pending
                transferTask.incrementRetryCount()

                // Mutate state under the lock, then do the client call outside it to avoid holding the lock across async work.
                let shouldTriggerReupload: Bool = try serialQueue.sync {
                    guard case .parts(let uploadId, let uploadFile, let partSize, var parts) = multipartUpload else {
                        throw Failure.invalidStateTransition
                    }
                    let part = try parts.find(partNumber: partNumber)
                    let index = partNumber - 1
                    parts[index] = .pending(bytes: part.bytes)
                    multipartUpload = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
                    let remainingParts = parts.filter { $0.inProgress }
                    return remainingParts.isEmpty
                }

                if shouldTriggerReupload {
                    // If there are no remaining parts in progress, manually trigger the reupload
                    let snapshot = serialQueue.sync { multipartUpload }
                    try client.uploadPart(partNumber: partNumber, multipartUpload: snapshot, subTask: createSubTask(partNumber: partNumber))
                }
            } else {
                throw Failure.partsUploadRetryLimitExceeded(underlyingError: error)
            }
        } catch {
            handle(multipartUploadEvent: .aborting(error: error))
        }
    }

    private func abort() throws {
        guard let uploadId = serialQueue.sync(execute: { multipartUpload.uploadId }) else {
            throw Failure.invalidStateTransition
        }
        try client.abortMultipartUpload(uploadId: uploadId)
    }

    private func cancelInProgressParts() {
        dispatchPrecondition(condition: .notOnQueue(serialQueue))
        // Read the parts under the lock rather than from the pause snapshot: a `.started` handled since then may
        // have returned a part to `.pending` (#4407). Nil when the upload is no longer paused.
        let taskIdentifiers: [TaskIdentifier]? = serialQueue.sync {
            guard case .paused(let uploadId, let uploadFile, let partSize, let parts) = multipartUpload else {
                logger.warn("Unable to get required values to cancel in progress parts: \(multipartUpload)")
                return nil
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
            return cancellingParts.compactMap { $0 }
        }
        guard let taskIdentifiers else { return }
        logger.debug("Cancelling upload tasks which are in process while paused: \(taskIdentifiers)")

        // Block while cancelling upload tasks, but not under the lock: URLSession calls back on its delegate queue,
        // behind delegate callbacks that themselves wait for the lock.
        let group = DispatchGroup()
        group.enter()
        client.cancelUploadTasks(taskIdentifiers: taskIdentifiers) {
            group.leave()
        }
        group.wait()
    }

    private func uploadParts(uploadFile: UploadFile, uploadId: UploadID, partSize: StorageUploadPartSize, parts: StorageUploadParts) {
        logger.debug(#function)

        guard inProgressCount < concurrentLimit else {
            logger.debug("Over concurrent limit, skipping...")
            return
        }

        do {
            let snapshot = serialQueue.sync { multipartUpload }
            let pendingPartNumbers = getPendingPartNumbers()
            logger.debug("Pending parts: \(pendingPartNumbers)")
            logger.debug("Multipart Upload: \(snapshot)")
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
                    // the next call does async work
                    let subTask = createSubTask(partNumber: partNumber)
                    logger.debug("Uploading part: \(partNumber)")
                    try client.uploadPart(partNumber: partNumber, multipartUpload: serialQueue.sync { multipartUpload }, subTask: subTask)
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
