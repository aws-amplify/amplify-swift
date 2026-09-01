//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `Sendable` because the session is held by the transfer machinery and reached from
///   URLSession delegate callbacks.
protocol StorageURLSession: Sendable {
    static var shared: StorageURLSession { get }
    func getActiveTasks(resultHandler: @escaping @Sendable (StorageSessionTasks) -> Void)
}

extension URLSession: StorageURLSession {
    func getActiveTasks(resultHandler: @escaping @Sendable (StorageSessionTasks) -> Void) {
        getAllTasks { tasks in
            resultHandler(tasks)
        }
    }
}

extension StorageURLSession {
    static var shared: StorageURLSession {
        URLSession.shared
    }
}
