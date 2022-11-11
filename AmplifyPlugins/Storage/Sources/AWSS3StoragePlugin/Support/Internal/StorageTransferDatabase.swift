//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

// The recovery process must load active tasks with URLSession and match them using taskIdentifier to a persisted task.
// Once the task can be "hydrated" the Event Handler can handle events from URLSession delegate methods. Tasks which
// are not matched can be deleted.

// swiftlint:disable line_length

/// Database protocol which supports the recovery process.
protocol StorageTransferDatabase {
    func insertTransferRequest(task: StorageActiveTransferTask)

    func updateTransferRequest(task: StorageActiveTransferTask)

    func removeTransferRequest(task: StorageActiveTransferTask)

    func prepareForBackground(completion: (() -> Void)?)

    func defaultTransferType(persistableTransferTask: StoragePersistableTransferTask) -> StorageTransferType?

    func recover(urlSession: StorageURLSession, completionHandler: @escaping (Result<StorageTransferTaskPairs, Error>) -> Void)

    func recover(urlSession: StorageURLSession) -> AmplifyAsyncThrowingSequence<StorageTransferTaskPair>

    func attachEventHandlers(onUpload: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler?,
                             onDownload: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler?,
                             onMultipartUpload: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler?)
}

extension StorageTransferDatabase {
    func prepareForBackground() {
        prepareForBackground(completion: nil)
    }

    func attachEventHandlers(onUpload: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler? = nil,
                             onDownload: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler? = nil,
                             onMultipartUpload: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler? = nil ) {
        attachEventHandlers(onUpload: onUpload, onDownload: onDownload, onMultipartUpload: onMultipartUpload)
    }

}
