//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `@unchecked Sendable`: the wrapped `URLSessionTask` is thread-safe and this
///   reference is handed to event callbacks that run off the calling thread.
class StorageTaskReference: @unchecked Sendable {
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
