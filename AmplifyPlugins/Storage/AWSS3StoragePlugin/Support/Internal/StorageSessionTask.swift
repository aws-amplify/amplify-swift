//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// abstraction which enables unit tests

typealias StorageSessionTasks = [StorageSessionTask]

protocol StorageSessionTask {
    var state: URLSessionTask.State { get }
    var taskIdentifier: TaskIdentifier { get }

    func resume()
    func suspend()
    func cancel()

}

extension StorageSessionTask {
    func resume() {}
    func suspend() {}
    func cancel() {}
}

extension URLSessionTask: StorageSessionTask {
}
