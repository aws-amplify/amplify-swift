//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias StorageTransferTaskPairs = [StorageTransferTaskPair]

struct StorageTransferTaskPair {
    let transferTask: StorageActiveTransferTask
    let multipartUpload: StorageMultipartUpload?

    init(transferTask: StorageActiveTransferTask,
         multipartUploads: [StorageMultipartUpload]) {
        self.transferTask = transferTask

        if let uploadId = transferTask.uploadId,
            let multipartUpload = multipartUploads.first(where: {
                $0.uploadId == uploadId
            }) {
            self.multipartUpload = multipartUpload
        } else {
            self.multipartUpload = nil
        }
    }
}
