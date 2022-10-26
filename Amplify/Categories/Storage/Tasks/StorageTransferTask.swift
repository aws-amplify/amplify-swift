//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum StorageTransferTask {
    case downloadData(task: StorageDownloadDataTask)
    case downloadFile(task: StorageDownloadFileTask)
    case uploadData(task: StorageUploadDataTask)
    case uploadFile(task: StorageUploadFileTask)
}

public struct StorageTransfer: RequestIdentifier {
    public let requestID: String
    public let task: StorageTransferTask
}
