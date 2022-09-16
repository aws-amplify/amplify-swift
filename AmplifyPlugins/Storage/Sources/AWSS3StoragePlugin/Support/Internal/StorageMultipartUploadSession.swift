//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Docs: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html

import Foundation
import Amplify

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

    private let queue = DispatchQueue(label: "com.amazon.aws.amplify.multipartupload-session", target: .global())
    private let id = UUID()
    private var multipartUpload: StorageMultipartUpload
    private let client: StorageMultipartUploadClient
    private let onEvent: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler

    private let transferTask: StorageTransferTask

    private var contentType: String? {
        transferTask.contentType
    }

    private var requestHeaders: RequestHeaders? {
        transferTask.requestHeaders
    }

    init(client: StorageMultipartUploadClient,
         bucket: String,
         key: String,
         contentType: String? = nil,
         requestHeaders: RequestHeaders? = nil,
         onEvent: @escaping AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler,
         behavior: StorageMultipartUploadBehavior = .progressive,
         fileSystem: FileSystem = .default,
         logger: Logger = storageLogger) {
        self.client = client

        let transferType: StorageTransferType = .multiPartUpload(onEvent: onEvent)
        let transferTask = StorageTransferTask(transferType: transferType,
                                               bucket: bucket,
                                               key: key,
                                               contentType: contentType,
                                               requestHeaders: requestHeaders)
        self.transferTask = transferTask
        self.onEvent = onEvent

        self.behavior = behavior
        self.fileSystem = fileSystem
        self.logger = logger

        multipartUpload = .none
        self.client.integrate(session: self)

        // attach session to transferTask
        transferTask.proxyStorageTask = self

        logger.info("Concurrency Limit is \(self.concurrentLimit) [based on active processors]")
    }

    init?(client: StorageMultipartUploadClient,
          transferTask: StorageTransferTask,
          multipartUpload: StorageMultipartUpload,
          behavior: StorageMultipartUploadBehavior = .progressive,
          fileSystem: FileSystem = .default,
          logger: Logger = storageLogger) {
        guard case let .multiPartUpload(onEvent) = transferTask.transferType else {
            return nil
        }

        self.client = client
        self.transferTask = transferTask
        self.multipartUpload = multipartUpload
        self.onEvent = onEvent

        self.behavior = behavior
        self.fileSystem = fileSystem
        self.logger = logger
    }

    func restart() {
        guard let uploadFile = multipartUpload.uploadFile,
              let uploadId = multipartUpload.uploadId,
              let partSize = multipartUpload.partSize,
              let parts = multipartUpload.parts else {
            return
        }
        uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
    }

    func createSubTask(partNumber: PartNumber) -> StorageTransferTask {
        guard let uploadId = multipartUpload.uploadId else {
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
        multipartUpload.uploadId
    }

    var completedParts: StorageUploadParts? {
        queue.sync {
            multipartUpload.parts?.completed
        }
    }

    var partsCount: Int {
        queue.sync {
            guard let parts = multipartUpload.parts else {
                return 0
            }

            let result = parts.count
            return result
        }
    }

    var partsCompleted: Bool {
        queue.sync {
            multipartUpload.partsCompleted
        }
    }

    var partsFailed: Bool {
        queue.sync {
            multipartUpload.partsFailed
        }
    }

    var inProgressCount: Int {
        queue.sync {
            guard let parts = multipartUpload.parts else {
                return 0
            }

            let result = parts.inProgress.count
            return result
        }
    }

    var isPaused: Bool {
        multipartUpload.isPaused
    }

    var isAborted: Bool {
        multipartUpload.isAborted
    }

    var isCompleted: Bool {
        multipartUpload.isCompleted
    }

    func getPendingPartNumbers() -> [Int] {
        queue.sync {
            multipartUpload.pendingPartNumbers
        }
    }

    func startUpload() {
        do {
            let reference = StorageTaskReference(transferTask)
            onEvent(.initiated(reference))
            try client.createMultipartUpload()
        } catch {
            fail(error: error)
        }
    }

    func fail(error: Error) {
        multipartUpload.fail(error: error)
        onEvent(.failed(StorageError(error: error)))
    }

    func handle(multipartUploadEvent: StorageMultipartUploadEvent) {
        logger.debug("\(#function): \(multipartUploadEvent)")

        do {
            try multipartUpload.transition(multipartUploadEvent: multipartUploadEvent)

            // update the transerTask with every state transition
            transferTask.multipartUpload = multipartUpload

            switch multipartUpload {
            case .parts(let uploadId, let uploadFile, let partSize, let parts):
                transferTask.uploadId = uploadId
                uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
            case .paused(_, _, _, let parts):
                cancelInProgressParts(parts: parts)
                transferTask.notify(progress: parts.progress)
            case .completed:
                onEvent(.completed(()))
            case .aborting:
                try abort()
            case .aborted:
                onEvent(.completed(()))
            case .failed(_, _, let error):
                onEvent(.failed(StorageError(error: error)))
            default:
                break
            }
        } catch {
            fail(error: error)
        }
    }

    func handle(uploadPartEvent: StorageUploadPartEvent) {
        logger.debug("\(#function): \(uploadPartEvent)")

        do {
            try multipartUpload.transition(uploadPartEvent: uploadPartEvent)

            // update the transferTask with every state transition
            transferTask.multipartUpload = multipartUpload

            if uploadPartEvent.isCompleted {
                // report progress
                if case .parts(_, _, _, let parts) = multipartUpload {
                    let progress = Progress.discreteProgress(totalUnitCount: Int64(parts.totalBytes))
                    progress.completedUnitCount = Int64(parts.bytesTransferred)
                    onEvent(.inProcess(progress))
                }
            }

            let isCompletedEvent = uploadPartEvent.isCompleted

            if case .queued = uploadPartEvent {
                return
            } else if isCompletedEvent && multipartUpload.hasPendingParts {
                if case .parts(let uploadId, let uploadFile, let partSize, let parts) = multipartUpload {
                    uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
                } else {
                    fatalError("Invalid state")
                }
            } else if partsCompleted {
                do {
                    try multipartUpload.validateForCompletion()
                } catch {
                    fail(error: error)
                    return
                }

                if let uploadId = multipartUpload.uploadId {
                    try client.completeMultipartUpload(uploadId: uploadId)
                } else {
                    fatalError("Invalid state")
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
                if case .parts(let uploadId, let uploadFile, let partSize, var parts) = multipartUpload {
                    let part = try parts.find(partNumber: partNumber)
                    let index = partNumber - 1
                    parts[index] = .pending(bytes: part.bytes)
                    multipartUpload = .parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
                } else {
                    fatalError("Invalid state")
                }
            } else {
                throw Failure.partsUploadRetryLimitExceeded(underlyingError: error)
            }
        } catch {
            handle(multipartUploadEvent: .aborting(error: error))
        }
    }

    private func abort() throws {
        if let uploadId = multipartUpload.uploadId {
            try client.abortMultipartUpload(uploadId: uploadId)
        } else {
            fatalError("Invalid state")
        }
    }

    private func cancelInProgressParts(parts: StorageUploadParts) {
        let taskIdentifiers = parts.inProgress.compactMap {
            if case .inProgress(_, _, let taskIdentifier) = $0 {
                return taskIdentifier
            } else {
                return nil
            }
        }

        client.cancelUploadTasks(taskIdentifiers: taskIdentifiers)

        queue.sync {
            if case .paused(let uploadId, let uploadFile, let partSize, let parts) = multipartUpload {
                let pausedParts = parts.map { part in
                    if case .inProgress = part {
                        return StorageUploadPart.pending(bytes: part.bytes)
                    } else {
                        return part
                    }
                }
                multipartUpload = .paused(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: pausedParts)
            }
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
            if pendingPartNumbers.isEmpty {
                return
            }
            let maxPartsCount = min(concurrentLimit, concurrentLimit - inProgressCount)
            if maxPartsCount > 0 {
                let end = min(maxPartsCount, pendingPartNumbers.count)
                let numbers = pendingPartNumbers[0..<end]
                // queue upload part first
                numbers.forEach { partNumber in
                    handle(uploadPartEvent: .queued(partNumber: partNumber))
                }

                // then start upload
                for partNumber in numbers {
                    guard !isAborted else { return }
                    // the next call does async work
                    let subTask = createSubTask(partNumber: partNumber)
                    try client.uploadPart(partNumber: partNumber, multipartUpload: multipartUpload, subTask: subTask)
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
