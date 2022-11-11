//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSS3StoragePlugin
@testable import Amplify

class MockStorageTransferDatabase: StorageTransferDatabase {

    private let queue = DispatchQueue(label: "com.amazon.aws.amplify.storage-tests",
                                      qos: .background,
                                      target: .global())
    private var tasks: [TransferID: StorageActiveTransferTask] = [:]

    private var uploadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler?
    private var downloadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler?
    private var multipartUploadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler?

    func insertTransferRequest(task: StorageActiveTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func updateTransferRequest(task: StorageActiveTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func removeTransferRequest(task: StorageActiveTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = nil
        }
    }

    func prepareForBackground(completion: (() -> Void)? = nil) {
        // do nothing
        completion?()
    }

    func recover(urlSession: StorageURLSession) -> AmplifyAsyncThrowingSequence<StorageTransferTaskPair> {
        Fatal.notImplemented()
    }

    func recover(urlSession: StorageURLSession,
                 completionHandler: @escaping (Result<StorageTransferTaskPairs, Error>) -> Void) {
        // do nothing
    }

    func defaultTransferType(persistableTransferTask: StoragePersistableTransferTask) -> StorageTransferType? {
        // swiftlint:disable line_length
        guard let rawValue = StorageTransferType.RawValues(rawValue: persistableTransferTask.transferTypeRawValue) else {
            return nil
        }
        // swiftlint:enable line_length

        let transferType: StorageTransferType?
        switch rawValue {
        case .download:
            transferType = .download(onEvent: handleDownloadEvent(event:))
        case .upload:
            transferType = .upload(onEvent: handleUploadEvent(event:))
        case .multiPartUpload:
            transferType = .multiPartUpload(onEvent: handleMultipartUploadEvent(event:))
        case .multiPartUploadPart:
            if let uploadId = persistableTransferTask.uploadId, let partNumber = persistableTransferTask.partNumber {
                transferType = .multiPartUploadPart(uploadId: uploadId, partNumber: partNumber)
            } else {
                transferType = nil
            }
        default:
            return nil
        }
        return transferType
    }

    // swiftlint:disable line_length
    func attachEventHandlers(onUpload: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler? = nil,
                             onDownload: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler? = nil,
                             onMultipartUpload: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler? = nil) {
        queue.async { [weak self] in
            guard let self = self else { fatalError("self cannot be weak") }
            self.uploadEventHandler = onUpload
            self.downloadEventHandler = onDownload
            self.multipartUploadEventHandler = onMultipartUpload
        }
    }
    // swiftlint:enable line_length

    private func handleUploadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceUploadEvent) {
        uploadEventHandler?(event)
    }

    private func handleDownloadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceDownloadEvent) {
        downloadEventHandler?(event)
    }

    private func handleMultipartUploadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEvent) {
        multipartUploadEventHandler?(event)
    }

}
