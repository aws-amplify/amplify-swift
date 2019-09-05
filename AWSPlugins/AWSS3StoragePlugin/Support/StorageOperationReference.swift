//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

// TODO: better naming - Reference?
public class StorageOperationReference {
    let task: AWSS3TransferUtilityTask
    init(_ task: AWSS3TransferUtilityTask) {
        self.task = task
    }
    func pause() {
        task.suspend()
        //task.taskIdentifier
    }

    func resume() {
        task.resume()
    }

    func cancel() {
        task.cancel()
    }
}
