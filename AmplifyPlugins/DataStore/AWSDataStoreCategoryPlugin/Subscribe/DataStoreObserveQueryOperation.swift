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
// swiftlint:disable:next type_body_length
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
    let dispatchedModelSyncedEvent: AtomicValue<Bool>
    let itemsChangedMaxSize: Int

    let stopwatch: Stopwatch
    var observeQueryStarted: Bool
    var currentItems: SortedList<M>
    var batchItemsChangedSink: AnyCancellable?
    var itemsChangedSink: AnyCancellable?
    var modelSyncedEventSink: AnyCancellable?

    /// Internal publisher for `ObserveQueryPublisher` to pass events back to subscribers
    let passthroughPublisher: PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>

    /// External subscribers subscribe to this publisher
    private let observeQueryPublisher: ObserveQueryPublisher<M>
    public var publisher: AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQueryPublisher.eraseToAnyPublisher()
    }

    var currentSnapshot: DataStoreQuerySnapshot<M> {
        DataStoreQuerySnapshot<M>(items: currentItems.sortedModels, isSynced: dispatchedModelSyncedEvent.get())
    }

    init(modelType: M.Type,
         modelSchema: ModelSchema,
         predicate: QueryPredicate?,
         sortInput: [QuerySortDescriptor]?,
         storageEngine: StorageEngineBehavior,
         dataStorePublisher: ModelSubcriptionBehavior,
         dataStoreConfiguration: DataStoreConfiguration,
         dispatchedModelSyncedEvent: AtomicValue<Bool>) {
        self.modelType = modelType
        self.modelSchema = modelSchema
        self.predicate = predicate
        self.sortInput = sortInput
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher
        self.dispatchedModelSyncedEvent = dispatchedModelSyncedEvent
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

        if let modelSyncedEventSink = modelSyncedEventSink {
            modelSyncedEventSink.cancel()
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
            self.currentItems.reset()
            self.itemsChangedSink = nil
            self.batchItemsChangedSink = nil
            self.modelSyncedEventSink = nil
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
        startSnapshotStopWatch()
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
                    currentItems.set(sortedModels: queriedModels)
                    subscribeToModelSyncedEvent()
                    sendSnapshot()
                case .failure(let error):
                    self.passthroughPublisher.send(completion: .failure(error))
                    self.finish()
                    return
                }
            })
    }

    // MARK: Observe item changes

    /// Subscribe to item changes with two subscribers (During Sync and After Sync). During Sync, the items are filtered
    /// by name and predicate, then collected by the timeOrCount grouping, before sent for processing the snapshot.
    /// After Sync, the item is only filtered by name, and not the predicate filter because updates to the item may
    /// make it so that the item no longer matches the predicate and requires to be removed from `currentItems`.
    /// This check is defered until `onItemChangedAfterSync` where the predicate is then used, and `currentItems` is
    /// accessed under the serial queue.
    func subscribeToItemChanges() {
        batchItemsChangedSink = dataStorePublisher.publisher
            .filter { _ in !self.dispatchedModelSyncedEvent.get() }
            .filter(filterByModelName(mutationEvent:))
            .filter(filterByPredicateMatch(mutationEvent:))
            .collect(.byTimeOrCount(serialQueue, itemsChangedPeriodicPublishTimeInSeconds, itemsChangedMaxSize))
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemsChangeDuringSync(mutationEvents:))

        itemsChangedSink = dataStorePublisher.publisher
            .filter { _ in self.dispatchedModelSyncedEvent.get() }
            .filter(filterByModelName(mutationEvent:))
            .receive(on: serialQueue)
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemChangeAfterSync(mutationEvent:))
    }

    func subscribeToModelSyncedEvent() {
        modelSyncedEventSink = Amplify.Hub.publisher(for: .dataStore).sink { event in
            if event.eventName == HubPayload.EventName.DataStore.modelSynced,
               let modelSyncedEvent = event.data as? ModelSyncedEvent,
               modelSyncedEvent.modelName == self.modelSchema.name {
                self.serialQueue.async {
                    self.sendSnapshot()
                }
            }
        }
    }

    func filterByModelName(mutationEvent: MutationEvent) -> Bool {
        // Filter in the model when it matches the model name for this operation
        mutationEvent.modelName == modelSchema.name
    }

    func filterByPredicateMatch(mutationEvent: MutationEvent) -> Bool {
        // Filter in the model when there is no predicate to check against.
        guard let predicate = self.predicate else {
            return true
        }
        do {
            let model = try mutationEvent.decodeModel(as: modelType)
            // Filter in the model when the predicate matches, otherwise filter out
            return predicate.evaluate(target: model)
        } catch {
            log.error(error: error)
            return false
        }
    }

    func onItemsChangeDuringSync(mutationEvents: [MutationEvent]) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            guard self.observeQueryStarted, !mutationEvents.isEmpty else {
                return
            }

            self.startSnapshotStopWatch()
            self.apply(itemsChanged: mutationEvents)
            self.sendSnapshot()
        }
    }

    // Item changes after sync is more elaborate than item changes during sync because the item was never filtered out
    // by the predicate (unlike during sync). An item that no longer matches the predicate may already exist in the
    // snapshot and now needs to be removed. The evaluation is done here under the serial queue since checking to
    // remove the item requires that check on `currentItems` and is required to be performed under the serial queue.
    func onItemChangeAfterSync(mutationEvent: MutationEvent) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            guard self.observeQueryStarted else {
                return
            }
            self.startSnapshotStopWatch()

            do {
                let model = try mutationEvent.decodeModel(as: self.modelType)
                guard let mutationType = MutationEvent.MutationType(rawValue: mutationEvent.mutationType) else {
                    return
                }

                guard let predicate = self.predicate else {
                    // 1. If there is no predicate, this item should be applied to the snapshot
                    if self.currentItems.apply(model: model, mutationType: mutationType) {
                        self.sendSnapshot()
                    }
                    return
                }

                // 2. When there is a predicate, evaluate further
                let modelMatchesPredicate = predicate.evaluate(target: model)

                guard !modelMatchesPredicate else {
                    // 3. When the item matchs the predicate, the item should be applied to the snapshot
                    if self.currentItems.apply(model: model, mutationType: mutationType) {
                        self.sendSnapshot()
                    }
                    return
                }

                // 4. When the item does not match the predicate, and is an update/delete, then the item needs to be
                // removed from `currentItems` because it no longer should be in the snapshot. If removing it was
                // was successfully, then send a new snapshot
                if mutationType == .update || mutationType == .delete, self.currentItems.remove(model) {
                    self.sendSnapshot()
                }
            } catch {
                self.log.error(error: error)
                return
            }

        }
    }

    /// Update `curentItems` list with the changed items.
    /// This method is not thread safe unless executed under the serial DispatchQueue `serialQueue`.
    private func apply(itemsChanged: [MutationEvent]) {
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

    private func startSnapshotStopWatch() {
        if log.logLevel >= .debug {
            stopwatch.start()
        }
    }

    private func sendSnapshot() {
        passthroughPublisher.send(currentSnapshot)
        if log.logLevel >= .debug {
            let time = stopwatch.stop()
            log.debug("Time to generate snapshot: \(time) seconds")
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
extension AWSDataStoreObserveQueryOperation: DefaultLogger { } // swiftlint:disable:this file_length
