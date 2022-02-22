//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

class StorageTaskReference {
    let task: StorageTask

    init(_ task: StorageTransferTask) {
        self.task = task
    }

    func pause() {
        task.pause()
    }

    func resume() {
        task.resume()
    }

    func cancel() {
        task.cancel()
    }
}
