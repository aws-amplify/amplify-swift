//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/*
Note: Multipart Uploads will have a request for the creation request, each part upload and the complete or abort
 requests. These tasks are persisted separately with a unique TransferID for each one where the create task will
 not have a sessionTask and so it will not have a taskIdentifier while each part upload will have a session Task
 and taskIdentifier and will be linked to the multipart upload by the uploadId and part number. When recovering
 from an app restart it will be necessary to compose these tasks back together to create an instance of
 MultiplePartUpload in the correct state. If there is not an uploadId it will not be persisted as the process has
 not started. If it has been persisted then there should be parts which will be subTasks which are loaded and each
 one may be completed already and have an eTag set, otherwise the sessionTask from URLSession will be able to
 provide the taskIdentifier which is necessary when the URLSession delegate methods are called which provide the
 taskIdentifier. This value is used to find the StorageActiveTransferTask so that updates can be reported with the
 onEvent closure which is given when the Storage operation is started.
 */

typealias StoragePersistableTransferTasks = [StoragePersistableTransferTask]

struct StoragePersistableTransferTask: Codable {
    let transferID: String
    let taskIdentifier: TaskIdentifier? // a multipart upload will not have a taskIdentifier
    let transferTypeRawValue: Int
    let bucket: String
    let key: String
    let contentType: String?
    let requestHeaders: [String: String]?
    let location: URL?

    let multipartUpload: StoragePersistableMultipartUpload?
    let subTask: StoragePersistableSubTask?

    var uploadId: UploadID? {
        multipartUpload?.uploadId ?? subTask?.uploadId
    }

    var partNumber: PartNumber? {
        subTask?.partNumber
    }

    var uploadFile: UploadFile? {
        guard let multipartUpload = multipartUpload else {
            return nil
        }

        let uploadFile = UploadFile(fileURL: multipartUpload.fileURL,
                                    temporaryFileCreated: multipartUpload.temporaryFileCreated,
                                    size: multipartUpload.size)
        return uploadFile
    }

    init(task: StorageActiveTransferTask) {
        self.transferID = task.transferID
        self.taskIdentifier = task.taskIdentifier
        self.transferTypeRawValue = task.transferType.rawValue
        self.bucket = task.bucket
        self.key = task.key
        self.contentType = task.contentType
        self.requestHeaders = task.requestHeaders
        self.location = task.location

        if case .multiPartUpload = task.transferType,
           let multipartUpload = task.multipartUpload {
            self.multipartUpload = StoragePersistableMultipartUpload(multipartUpload: multipartUpload)
            subTask = nil
        } else if case .multiPartUploadPart = task.transferType,
                  let uploadId = task.uploadId,
                  let partNumber = task.partNumber,
                  let part = task.uploadPart {
            self.multipartUpload = nil
            self.subTask = StoragePersistableSubTask(uploadId: uploadId, partNumber: partNumber, part: part)
        } else {
            self.multipartUpload = nil
            self.subTask = nil
        }
    }

}

struct StoragePersistableMultipartUpload: Codable {
    let uploadId: UploadID
    let fileURL: URL
    let temporaryFileCreated: Bool
    let size: UInt64

    init?(multipartUpload: StorageMultipartUpload) {
        guard let uploadId = multipartUpload.uploadId,
                  let fileURL = multipartUpload.uploadFile?.fileURL,
                  let temporaryFileCreated = multipartUpload.uploadFile?.temporaryFileCreated,
                  let size = multipartUpload.uploadFile?.size else {
            return nil
        }
        self.uploadId = uploadId
        self.fileURL = fileURL
        self.temporaryFileCreated = temporaryFileCreated
        self.size = size
    }
}

struct StoragePersistableSubTask: Codable {
    let uploadId: UploadID
    let partNumber: PartNumber
    let bytes: Int
    let bytesTransferred: Int
    let taskIdentifier: TaskIdentifier? // once an UploadPart starts uploading it will have a taskIdentifier
    let eTag: String?

    init(uploadId: UploadID, partNumber: PartNumber, part: StorageUploadPart) {
        self.uploadId = uploadId
        self.partNumber = partNumber
        self.bytes = part.bytes
        self.bytesTransferred = part.bytesTransferred
        self.taskIdentifier = part.taskIdentifier
        self.eTag = part.eTag
    }
}

extension UploadFile {
    init(multipartUpload: StoragePersistableMultipartUpload) {
        self.fileURL = multipartUpload.fileURL
        self.temporaryFileCreated = multipartUpload.temporaryFileCreated
        self.size = multipartUpload.size
    }
}
