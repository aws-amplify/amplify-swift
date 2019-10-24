//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Maps APIOperations to HTTPTransportTasks, providing convenience methods for accessing them
struct OperationTaskMapper {
    private static let concurrencyQueue = DispatchQueue(label: "com.amazonaws.OperationTaskMapper.concurrency")

    private var operations = [UUID: APIOperation]()
    private var tasks = [Int: HTTPTransportTask]()
    private var operationIdsByTaskId = [Int: UUID]()
    private var taskIdsByOperationId = [UUID: Int]()

    mutating func addPair(operation: APIOperation, task: HTTPTransportTask) {
        OperationTaskMapper.concurrencyQueue.sync {
            operations[operation.id] = operation
            tasks[task.taskIdentifier] = task
            taskIdsByOperationId[operation.id] = task.taskIdentifier
            operationIdsByTaskId[task.taskIdentifier] = operation.id
        }
    }

    mutating func removePair(for operation: APIOperation) {
        OperationTaskMapper.concurrencyQueue.sync {
            let taskId = taskIdsByOperationId[operation.id]
            removePair(operationId: operation.id, taskId: taskId)
        }
    }

    mutating func removePair(for task: HTTPTransportTask) {
        OperationTaskMapper.concurrencyQueue.sync {
            let operationId = operationIdsByTaskId[task.taskIdentifier]
            removePair(operationId: operationId, taskId: task.taskIdentifier)
        }
    }

    func operation(for task: HTTPTransportTask) -> APIOperation? {
        return OperationTaskMapper.concurrencyQueue.sync {
            guard let operationId = operationIdsByTaskId[task.taskIdentifier] else {
                return nil
            }

            return operations[operationId]
        }
    }

    func task(for operation: APIOperation) -> HTTPTransportTask? {
        return OperationTaskMapper.concurrencyQueue.sync {
            guard let taskId = taskIdsByOperationId[operation.id] else {
                return nil
            }

            return tasks[taskId]
        }
    }

    func reset() {
        OperationTaskMapper.concurrencyQueue.sync {
            operations.values.forEach { $0.cancel() }
            tasks.values.forEach { $0.cancel() }
        }
    }

    /// Not inherently thread safe--this must be called from `concurrencyQueue`
    private mutating func removePair(operationId: UUID?, taskId: Int?) {
        OperationTaskMapper.concurrencyQueue.sync {
            if let operationId = operationId {
                operations[operationId] = nil
                taskIdsByOperationId[operationId] = nil
            }
            if let taskId = taskId {
                tasks[taskId] = nil
                operationIdsByTaskId[taskId] = nil
            }
        }
    }
}
