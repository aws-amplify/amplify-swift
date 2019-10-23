//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Encapsulates the behavior required for a single HTTP operation, including
/// identifying, pausing/resuming, and cancelling. Behind the scenes, this will be
/// backed by a URLSessionTask.
protocol HTTPTransportTask {
    var taskIdentifier: Int { get }
}

/// Defines behaviors used during fulfillment of HTTPTransportTasks.
protocol HTTPTransportTaskDelegate: class {
    func task(_ httpTransportTask: HTTPTransportTask, didReceiveData data: Data)
}
