//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

protocol DataStoreObserveQueryOperation {
    func resetState()
    func startObserveQuery(with storageEngine: StorageEngineBehavior)
}

@available(iOS 13.0, *)
public class ObserveQueryPublisher<M: Model>: Publisher {
    public typealias Output = DataStoreQuerySnapshot<M>
    public typealias Failure = DataStoreError

    weak var operation: AWSDataStoreObserveQueryOperation<M>?

    func configure(operation: AWSDataStoreObserveQueryOperation<M>) {
        self.operation = operation
    }

    public func receive<S>(subscriber: S)
    where S: Subscriber, ObserveQueryPublisher.Failure == S.Failure, ObserveQueryPublisher.Output == S.Input {
        let subscription = ObserveQuerySubscription<S, M>(operation: operation)
        subscription.target = subscriber
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 13.0, *)
class ObserveQuerySubscription<Target: Subscriber, M: Model>: Subscription
where Target.Input == DataStoreQuerySnapshot<M>, Target.Failure == DataStoreError {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.ObserveQuerySubscription.serialQueue",
                                            target: DispatchQueue.global())
    var target: Target?
    var sink: AnyCancellable?
    weak var operation: AWSDataStoreObserveQueryOperation<M>?

    init(operation: AWSDataStoreObserveQueryOperation<M>?) {
        self.operation = operation
        self.sink = operation?
            .passthroughPublisher
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onReceiveValue(snapshot:))
    }

    func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        serialQueue.async {
            self.target?.receive(completion: completed)
            self.target = nil
            self.sink = nil
            self.operation = nil
        }
    }

    func onReceiveValue(snapshot: DataStoreQuerySnapshot<M>) {
        _ = target?.receive(snapshot)
    }

    /// This subscription doesn't respond to demand, since it'll
    /// simply emit events according to its underlying operation
    /// but we still have to implement this method
    /// in order to conform to the Subscription protocol:
    func request(_ demand: Subscribers.Demand) {
        if demand != .unlimited {
            log.verbose("Setting the Demand is not supported. The subscriber will receive all values for this API.")
        }

    }

    /// When the subscription is cancelled, cancel the underlying operation
    func cancel() {
        serialQueue.async {
            self.operation?.cancel()
        }
    }

    /// When app code recreates the subscription, the previous subscription
    /// will be deallocated. At this time, cancel the underlying operation
    deinit {
        self.operation?.cancel()
        self.target = nil
        self.sink = nil
        self.operation = nil
    }
}

@available(iOS 13.0, *)
extension ObserveQuerySubscription: DefaultLogger { }

/// Publishes a stream of `DataStoreQuerySnapshot` events.
///
/// Flow: When the operation starts executing
///     - Subscribe to DataStore hub events
///     - Subscribe to Item changes
///     - Perform initial query to set up the internal state of the items
///     - Generate first snapshot based on the internal state
///     When the operation receives item changes
///     - Batch them into batches of up to 1000 items or when 2 seconds have elapsed (`.collect(2s,1000)`)`
///     - Update internal state of items based on the changed items
///     - Generate new snapshot based on latest state of the items.
///
/// This operation should perform its methods under the serial DispatchQueue `serialQueue` to ensure all its properties
/// remain thread-safe.
@available(iOS 13.0, *)
public class AWSDataStoreObserveQueryOperation<M: Model>: AsynchronousOperation, DataStoreObserveQueryOperation {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.AWSDataStoreObseverQueryOperation.serialQueue",
                                            target: DispatchQueue.global())
    private let itemsChangedPeriodicPublishTimeInSeconds: DispatchQueue.SchedulerTimeType.Stride = 2

    let modelType: M.Type
    let modelSchema: ModelSchema
    let predicate: QueryPredicate?
    let sortInput: [QuerySortDescriptor]?
    var storageEngine: StorageEngineBehavior
    var dataStorePublisher: ModelSubcriptionBehavior
    let itemsChangedMaxSize: Int

    let stopwatch: Stopwatch
    var observeQueryStarted: Bool
    var currentItems: SortedList<M>
    var batchItemsChangedSink: AnyCancellable?
    var itemsChangedSink: AnyCancellable?

    /// Internal publisher for `ObserveQueryPublisher` to pass events back to subscribers
    let passthroughPublisher: PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>

    /// External subscribers subscribe to this publisher
    private let observeQueryPublisher: ObserveQueryPublisher<M>
    public var publisher: AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQueryPublisher.eraseToAnyPublisher()
    }

    var isSynced: Bool {
        if let storageAdapter = storageEngine as? StorageEngine,
           let remoteSyncEngine = storageAdapter.syncEngine as? RemoteSyncEngine,
           let modelSyncedEventEmitter = remoteSyncEngine
            .syncEventEmitter?.modelSyncedEventEmitters[modelType.modelName] {
            return modelSyncedEventEmitter.dispatchedModelSyncedEvent
        }
        return false
    }

    var currentSnapshot: DataStoreQuerySnapshot<M> {
        DataStoreQuerySnapshot<M>(items: currentItems.sortedModels, isSynced: isSynced)
    }

    init(modelType: M.Type,
         modelSchema: ModelSchema,
         predicate: QueryPredicate?,
         sortInput: [QuerySortDescriptor]?,
         storageEngine: StorageEngineBehavior,
         dataStorePublisher: ModelSubcriptionBehavior,
         dataStoreConfiguration: DataStoreConfiguration) {
        self.modelType = modelType
        self.modelSchema = modelSchema
        self.predicate = predicate
        self.sortInput = sortInput
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher
        self.itemsChangedMaxSize = Int(dataStoreConfiguration.syncPageSize)
        self.stopwatch = Stopwatch()
        self.observeQueryStarted = false
        self.currentItems = SortedList(sortInput: sortInput, modelSchema: modelSchema)
        self.passthroughPublisher = PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>()
        self.observeQueryPublisher = ObserveQueryPublisher()
        super.init()
        observeQueryPublisher.configure(operation: self)
    }

    override public func main() {
        startObserveQuery()
    }

    override public func cancel() {
        if let itemsChangedSink = itemsChangedSink {
            itemsChangedSink.cancel()
        }

        if let batchItemsChangedSink = batchItemsChangedSink {
            batchItemsChangedSink.cancel()
        }
        passthroughPublisher.send(completion: .finished)
        super.cancel()
        finish()
    }

    func resetState() {
        serialQueue.async {
            if !self.observeQueryStarted {
                return
            } else {
                self.observeQueryStarted = false
            }
            self.log.verbose("Resetting state")
            self.currentItems.sortedModels.removeAll()
            self.itemsChangedSink = nil
            self.batchItemsChangedSink = nil
        }
    }

    func startObserveQuery(with storageEngine: StorageEngineBehavior) {
        startObserveQuery(storageEngine)
    }

    private func startObserveQuery(_ storageEngine: StorageEngineBehavior? = nil) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }

            if self.observeQueryStarted {
                return
            } else {
                self.observeQueryStarted = true
            }

            if let storageEngine = storageEngine {
                self.storageEngine = storageEngine
            }
            self.log.verbose("Start ObserveQuery")
            self.subscribeToItemChanges()
            self.initialQuery()
        }
    }

    // MARK: - Query

    func initialQuery() {
        if isCancelled || isFinished {
            finish()
            return
        }
        if log.logLevel >= .debug {
            stopwatch.start()
        }
        storageEngine.query(
            modelType,
            modelSchema: modelSchema,
            predicate: predicate,
            sort: sortInput,
            paginationInput: nil,
            completion: { queryResult in
                if isCancelled || isFinished {
                    finish()
                    return
                }

                switch queryResult {
                case .success(let queriedModels):
                    currentItems.sortedModels = queriedModels
                    generateQuerySnapshot()
                case .failure(let error):
                    self.passthroughPublisher.send(completion: .failure(error))
                    self.finish()
                    return
                }
            })
    }

    // MARK: Observe item changes

    func subscribeToItemChanges() {
        batchItemsChangedSink = dataStorePublisher.publisher
            .filter { _ in !self.isSynced }
            .filter(onItemChangedFilter(mutationEvent:))
            .collect(.byTimeOrCount(serialQueue, itemsChangedPeriodicPublishTimeInSeconds, itemsChangedMaxSize))
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemsChange(mutationEvents:))

        itemsChangedSink = dataStorePublisher.publisher
            .filter { _ in self.isSynced }
            .filter(onItemChangedFilter(mutationEvent:))
            .receive(on: serialQueue)
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemChange(mutationEvent:))
    }

    func onItemChangedFilter(mutationEvent: MutationEvent) -> Bool {
        guard mutationEvent.modelName == modelSchema.name else {
            return false
        }

        guard let predicate = self.predicate else {
            return true
        }

        do {
            let model = try mutationEvent.decodeModel(as: modelType)
            return predicate.evaluate(target: model)
        } catch {
            log.error(error: error)
            return false
        }
    }

    func onItemChange(mutationEvent: MutationEvent) {
        onItemsChange(mutationEvents: [mutationEvent])
    }

    func onItemsChange(mutationEvents: [MutationEvent]) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            guard self.observeQueryStarted, !mutationEvents.isEmpty else {
                return
            }
            if self.log.logLevel >= .debug {
                self.stopwatch.start()
            }
            self.generateQuerySnapshot(itemsChanged: mutationEvents)
        }
    }

    private func generateQuerySnapshot(itemsChanged: [MutationEvent] = []) {
        updateCurrentItems(with: itemsChanged)
        passthroughPublisher.send(currentSnapshot)
        if log.logLevel >= .debug {
            let time = stopwatch.stop()
            log.debug("Time to generate snapshot: \(time) seconds")
        }
    }

    /// Update `curentItems` list with the changed items.
    /// This method is not thread safe unless executed under the serial DispatchQueue `serialQueue`.
    private func updateCurrentItems(with itemsChanged: [MutationEvent]) {
        for item in itemsChanged {
            do {
                let model = try item.decodeModel(as: modelType)
                guard let mutationType = MutationEvent.MutationType(rawValue: item.mutationType) else {
                    return
                }
                currentItems.apply(model: model, mutationType: mutationType)
            } catch {
                log.error(error: error)
                continue
            }
        }
    }

    private func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        if isCancelled || isFinished {
            finish()
            return
        }
        switch completed {
        case .finished:
            passthroughPublisher.send(completion: .finished)
        case .failure(let error):
            passthroughPublisher.send(completion: .failure(error))
        }
        finish()
    }
}

@available(iOS 13.0, *)
extension AWSDataStoreObserveQueryOperation: DefaultLogger { }
