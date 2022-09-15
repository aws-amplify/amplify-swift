//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum StorageMultipartUploadEvent {
    case creating
    case pausing
    case resuming
    case created(uploadFile: UploadFile, uploadId: UploadID)
    case completing(taskIdentifier: TaskIdentifier)
    case completed(uploadId: UploadID)
    case aborting(error: Error?)
    case aborted(uploadId: UploadID, error: Error?)
    case failed(uploadId: UploadID?, error: Error)
}
