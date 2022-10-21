//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class StorageTaskReference {
    let task: StorageTask

    init(_ task: StorageActiveTransferTask) {
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
