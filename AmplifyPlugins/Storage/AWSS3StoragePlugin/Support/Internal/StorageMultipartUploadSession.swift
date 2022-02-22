//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Docs: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html

// TODO: determine what happens if a multipart upload is aborted while uploading parts
// create a model for it to use with unit tests
//
// Code: NoSuchUpload
// Cause: The specified multipart upload does not exist. The upload ID might be invalid, or the multipart upload might have been aborted or completed.
// HTTP Status Code: 404 Not Found

import Foundation
import AWSS3
import Amplify

typealias RequestHeaders = [String : String]
typealias RequestParameters = [String : String]

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
    }

    private let behavior: StorageMultipartUploadBehavior
    private let fileSystem: FileSystem
    private let logger: Logger

    private let queue = DispatchQueue(label: "com.amazon.aws.amplify.multipartupload-session", target: .global())
    private let id = UUID()
    fileprivate var multipartUpload: StorageMultipartUpload
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

    func resume() {
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

    var isCompleted: Bool {
        multipartUpload.isCompleted
    }

    func getPendingPartNumbers() -> [Int] {
        queue.sync {
            multipartUpload.pendingPartNumbers
        }
    }

    // Finite State Machine: State, Transition, Events

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
            case .completed:
                onEvent(.completed(()))
            case .aborted:
                onEvent(.completed(()))
            case .failed(_, _, let error):
                onEvent(.failed(StorageError(error: error)))
            default:
                break
            }
        } catch {
            // TODO: determine if a retry should be attempted
            fail(error: error)
        }
    }

    func handle(uploadPartEvent: StorageUploadPartEvent) {
        logger.debug("\(#function): \(uploadPartEvent)")

        // TODO: let go of upload task with taskIdentifier when completed

        do {
            let taskIdentifier = uploadPartEvent.taskIdentifier
            try multipartUpload.transition(uploadPartEvent: uploadPartEvent)

            // update the transerTask with every state transition
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
            if isCompletedEvent, let taskIdentifier = taskIdentifier {
                // TODO: unregister task
            }

            if case .queued = uploadPartEvent {
                return
            } else if isCompletedEvent && multipartUpload.hasPendingParts {
                if case .parts(let uploadId, let uploadFile, let partSize, let parts) = multipartUpload {
                    uploadParts(uploadFile: uploadFile, uploadId: uploadId, partSize: partSize, parts: parts)
                } else {
                    fatalError("Invalid state")
                }
            } else if partsCompleted {
                if let uploadId = multipartUpload.uploadId {
                    try client.completeMultipartUpload(uploadId: uploadId)
                } else {
                    fatalError("Invalid state")
                }
            } else if partsFailed {
                if let uploadId = multipartUpload.uploadId {
                    try client.abortMultipartUpload(uploadId: uploadId)
                } else {
                    fatalError("Invalid state")
                }
            }
        } catch {
            // TODO: determine if a retry should be attempted
            fail(error: error)
        }
    }

    func uploadParts(uploadFile: UploadFile, uploadId: UploadID, partSize: StorageUploadPartSize, parts: StorageUploadParts) {
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
                var lastNumber: Int? = 0
                // queue upload part first
                numbers.forEach { partNumber in
                    handle(uploadPartEvent: .queued(partNumber: partNumber))
                }

                // then start upload
                try numbers.forEach { partNumber in
                    // the next call does async work
                    let subTask = createSubTask(partNumber: partNumber)
                    try client.uploadPart(partNumber: partNumber, multipartUpload: multipartUpload, subTask: subTask)

                    lastNumber = partNumber
                }
                print("Stopped at \(lastNumber ?? 0)")
            }
        } catch {
            // TODO: determine if a retry should be attempted
            fail(error: error)
        }
    }

}

enum StorageMultipartUploadSessionEvent {
    case progress(bytesTransferred: Int)
    case completed(eTag: String?, error: Error?)
}

extension StorageMultipartUploadSession: Equatable {
    static func == (lhs: StorageMultipartUploadSession, rhs: StorageMultipartUploadSession) -> Bool {
        lhs.id == rhs.id
    }
}


// TODO: maybe not do this
extension Sequence where Element == StorageMultipartUploadSession {
    // find task by taskIdentifier
    func findMultipartUpload(taskIdentifier: TaskIdentifier) -> StorageMultipartUpload? {
        first {
            $0.multipartUpload.taskIdentifier == taskIdentifier
        }.map {
            $0.multipartUpload
        }
    }
    func findUploadPart(taskIdentifier: TaskIdentifier) -> StorageUploadPart? {
        return nil
    }
}
