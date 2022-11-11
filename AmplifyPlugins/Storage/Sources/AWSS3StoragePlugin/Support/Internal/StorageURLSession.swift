//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol StorageURLSession {
    static var shared: StorageURLSession { get }
//    func getActiveTasks(resultHandler: @escaping (StorageSessionTasks) -> Void)
    var allTasks: [StorageSessionTask] { get async }
}

extension URLSession: StorageURLSession {
//    var allTasks: [URLSessionTask] {
//
//
//    }
    var allTasks: [StorageSessionTask] {
        get async {
            await withCheckedContinuation({ continuation in
                getAllTasks { tasks in
                    continuation.resume(returning: tasks)
                }
            })
        }
    }
//    func getActiveTasks(resultHandler: @escaping (StorageSessionTasks) -> Void) {
//        getAllTasks { tasks in
//            resultHandler(tasks)
//        }
//    }
}

extension StorageURLSession where Self == URLSession {
}

extension StorageURLSession {
    static var shared: StorageURLSession {
        URLSession.shared
    }
}
