//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

struct AWSS3TransferUtilityTask {
    var transferID: String = UUID().uuidString
}

class StorageTaskReference {
    let task: AWSS3TransferUtilityTask?
//    let multiPartUploadTask: AWSS3TransferUtilityMultiPartUploadTask?

    init(_ task: AWSS3TransferUtilityTask) {
        self.task = task
//        self.multiPartUploadTask = nil
    }

    /*
    init(_ task: AWSS3TransferUtilityMultiPartUploadTask) {
        self.task = nil
        self.multiPartUploadTask = task
    }
     */

    func pause() {
//        task?.suspend()
//        multiPartUploadTask?.suspend()
    }

    func resume() {
//        task?.resume()
//        multiPartUploadTask?.resume()
    }

    func cancel() {
//        task?.cancel()
//        multiPartUploadTask?.cancel()
    }
}
