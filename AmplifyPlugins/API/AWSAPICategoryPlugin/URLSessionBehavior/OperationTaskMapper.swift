//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Maps operations, which conform to `APIOperation`, to URLSessionTaskBehaviors and
/// provides convenience methods for accessing them
class OperationTaskMapper {
    private static let concurrencyQueue = DispatchQueue(label: "com.amazonaws.OperationTaskMapper.concurrency")

    var operations = [UUID: APIOperation]()
    var tasks = [Int: URLSessionDataTaskBehavior]()
    var operationIdsByTaskId = [Int: UUID]()
    var taskIdsByOperationId = [UUID: Int]()

    func addPair(operation: APIOperation, task: URLSessionDataTaskBehavior) {
        OperationTaskMapper.concurrencyQueue.sync {
            operations[operation.getOperationId()] = operation
            tasks[task.taskBehaviorIdentifier] = task
            taskIdsByOperationId[operation.getOperationId()] = task.taskBehaviorIdentifier
            operationIdsByTaskId[task.taskBehaviorIdentifier] = operation.getOperationId()
        }
    }

    func removePair(for operation: APIOperation) {
        OperationTaskMapper.concurrencyQueue.sync {
            let taskId = taskIdsByOperationId[operation.getOperationId()]
            removePair(operationId: operation.getOperationId(), taskId: taskId)
        }
    }

    func removePair(for task: URLSessionDataTaskBehavior) {
        OperationTaskMapper.concurrencyQueue.sync {
            let operationId = operationIdsByTaskId[task.taskBehaviorIdentifier]
            removePair(operationId: operationId, taskId: task.taskBehaviorIdentifier)
        }
    }

    func operation(for task: URLSessionDataTaskBehavior) -> APIOperation? {
        return OperationTaskMapper.concurrencyQueue.sync {
            guard let operationId = operationIdsByTaskId[task.taskBehaviorIdentifier] else {
                return nil
            }

            if let operation = operations[operationId] {
                return operation
            }

            return nil
        }
    }

    func task(for operation: APIOperation) -> URLSessionDataTaskBehavior? {
        return OperationTaskMapper.concurrencyQueue.sync {
            guard let taskId = taskIdsByOperationId[operation.getOperationId()] else {
                return nil
            }

            return tasks[taskId]
        }
    }

    func reset() {
        OperationTaskMapper.concurrencyQueue.sync {
            operations.values.forEach { $0.cancelOperation() }
            tasks.values.forEach { $0.cancel() }
        }
    }

    /// Not inherently thread safe--this must be called from `concurrencyQueue`
    private func removePair(operationId: UUID?, taskId: Int?) {
        dispatchPrecondition(condition: .onQueue(Self.concurrencyQueue))
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
