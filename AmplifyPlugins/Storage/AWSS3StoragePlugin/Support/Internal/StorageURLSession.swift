//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol StorageURLSession {
    static var shared: StorageURLSession { get }
    func getActiveTasks(resultHandler: @escaping (StorageSessionTasks) -> Void)
}

extension URLSession: StorageURLSession {
    func getActiveTasks(resultHandler: @escaping (StorageSessionTasks) -> Void) {
        getAllTasks { tasks in
            resultHandler(tasks)
        }
    }
}

extension StorageURLSession where Self == URLSession {
}

extension StorageURLSession {
    static var shared: StorageURLSession {
        URLSession.shared
    }
}
