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
    private var tasks: [TransferID: StorageTransferTask] = [:]

    private var uploadEventHandler: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler?
    private var downloadEventHandler: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler?
    private var multipartUploadEventHandler: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler?

    func insertTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func updateTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func removeTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = nil
        }
    }

    func prepareForBackground(completion: (() -> Void)? = nil) {
        // do nothing
        completion?()
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
    func attachEventHandlers(onUpload: AWSS3StorageServiceBehavior.StorageServiceUploadEventHandler? = nil,
                             onDownload: AWSS3StorageServiceBehavior.StorageServiceDownloadEventHandler? = nil,
                             onMultipartUpload: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEventHandler? = nil) {
        queue.async { [weak self] in
            guard let self = self else { fatalError("self cannot be weak") }
            self.uploadEventHandler = onUpload
            self.downloadEventHandler = onDownload
            self.multipartUploadEventHandler = onMultipartUpload
        }
    }
    // swiftlint:enable line_length

    private func handleUploadEvent(event: AWSS3StorageServiceBehavior.StorageServiceUploadEvent) {
        uploadEventHandler?(event)
    }

    private func handleDownloadEvent(event: AWSS3StorageServiceBehavior.StorageServiceDownloadEvent) {
        downloadEventHandler?(event)
    }

    private func handleMultipartUploadEvent(event: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEvent) {
        multipartUploadEventHandler?(event)
    }

}
