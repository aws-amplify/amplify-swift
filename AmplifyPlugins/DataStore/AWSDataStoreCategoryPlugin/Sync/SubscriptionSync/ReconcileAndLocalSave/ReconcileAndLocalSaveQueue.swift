//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

@available(iOS 13.0, *)
protocol ReconcileAndSaveOperationQueue {
    func addOperation(_ operation: ReconcileAndLocalSaveOperation, modelName: String)

    func cancelOperations(modelName: String)

    func cancelAllOperations()

    func waitUntilOperationsAreFinished()

    init(_ modelSchemas: [ModelSchema])
}

enum ReoncileAndSaveQueueEvent {
    case operationAdded(id: UUID)
    case operationRemoved(id: UUID)
    case cancelledOperations(modelName: String)
}

/// A queue used to enqueue `ReconcileAndLocalSaveOperation`s which perform reconcile and save for incoming mutation
/// sync events to local storage for all model types.
///
/// Internally, a `ReconcileAndSaveQueue` will manage an operation queue with concurrency of 1 to perform serial
/// operations to ensure events are processed in the order in which they are received. For example, an initial sync
/// will perform sync queries for models based on its dependency order. The results are then processed serially by this
/// queue to ensure the events are reconciled in the same dependency order in which they are received by the
/// sync query response.
///
/// Additionally, this queue allows per model type cancellations on the operations that are enqueued by calling
/// `cancelOperations(modelName)`. This allows per model type clean up, while allowing other model reconcilliations to
/// continue to operate.
@available(iOS 13.0, *)
class ReconcileAndSaveQueue: ReconcileAndSaveOperationQueue {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndSaveQueue.serialQueue",
                                                 target: DispatchQueue.global())
    private let reconcileAndSaveQueue: OperationQueue
    private var modelReconcileAndSaveOperations = [String: [UUID: ReconcileAndLocalSaveOperation]]()
    private var reconcileAndLocalSaveOperationSinks: AtomicValue<Set<AnyCancellable?>>

    private let reconcileAndSaveQueueSubject: PassthroughSubject<ReoncileAndSaveQueueEvent, DataStoreError>
    var publisher: AnyPublisher<ReoncileAndSaveQueueEvent, DataStoreError> {
        return reconcileAndSaveQueueSubject.eraseToAnyPublisher()
    }
    required init(_ modelSchemas: [ModelSchema]) {
        self.reconcileAndSaveQueueSubject = PassthroughSubject<ReoncileAndSaveQueueEvent, DataStoreError>()
        self.reconcileAndSaveQueue = OperationQueue()
        reconcileAndSaveQueue.name = "com.amazonaws.DataStore.reconcile"
        reconcileAndSaveQueue.maxConcurrentOperationCount = 1
        reconcileAndSaveQueue.underlyingQueue = DispatchQueue.global()
        reconcileAndSaveQueue.isSuspended = false

        for model in modelSchemas {
            modelReconcileAndSaveOperations[model.name] = [UUID: ReconcileAndLocalSaveOperation]()
        }
        self.reconcileAndLocalSaveOperationSinks = AtomicValue(initialValue: Set<AnyCancellable?>())
    }

    func addOperation(_ operation: ReconcileAndLocalSaveOperation, modelName: String) {
        serialQueue.async {
            var reconcileAndLocalSaveOperationSink: AnyCancellable?

            reconcileAndLocalSaveOperationSink = operation.publisher.sink { [weak self] _ in
                self?.reconcileAndLocalSaveOperationSinks.with { $0.remove(reconcileAndLocalSaveOperationSink) }
                self?.modelReconcileAndSaveOperations[modelName]?[operation.id] = nil
                self?.reconcileAndSaveQueueSubject.send(.operationRemoved(id: operation.id))
            } receiveValue: { _ in }

            self.reconcileAndLocalSaveOperationSinks.with { $0.insert(reconcileAndLocalSaveOperationSink) }
            self.modelReconcileAndSaveOperations[modelName]?[operation.id] = operation
            self.reconcileAndSaveQueue.addOperation(operation)
            self.reconcileAndSaveQueueSubject.send(.operationAdded(id: operation.id))
        }
    }

    func cancelOperations(modelName: String) {
        serialQueue.async {
            if let operations = self.modelReconcileAndSaveOperations[modelName] {
                operations.values.forEach { operation in
                    operation.cancel()
                }
            }
            self.modelReconcileAndSaveOperations[modelName]?.removeAll()
            self.reconcileAndSaveQueueSubject.send(.cancelledOperations(modelName: modelName))
        }
    }

    func cancelAllOperations() {
        serialQueue.async {
            self.reconcileAndSaveQueue.cancelAllOperations()
            for (modelName, _) in self.modelReconcileAndSaveOperations {
                self.modelReconcileAndSaveOperations[modelName]?.removeAll()
                self.reconcileAndSaveQueueSubject.send(.cancelledOperations(modelName: modelName))
            }
        }
    }

    // This method blocks the current thread by not executing the work on the serial queue since underlying operation
    // queue's `waitUntilAllOperationsAreFinished()` behaves the same way. See the following link for more details:
    // https://developer.apple.com/documentation/foundation/operationqueue/1407971-waituntilalloperationsarefinishe
    func waitUntilOperationsAreFinished() {
        reconcileAndSaveQueue.waitUntilAllOperationsAreFinished()
    }
}
