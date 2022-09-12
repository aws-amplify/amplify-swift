//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum StorageActiveTransferTask {
    case downloadData(task: StorageDownloadDataTask)
    case downloadFile(task: StorageDownloadFileTask)
    case uploadData(task: StorageUploadDataTask)
    case uploadFile(task: StorageUploadFileTask)
}

public struct StorageActiveTransfer: RequestIdentifier {
    public let requestID: String
    public let task: StorageActiveTransferTask
}
