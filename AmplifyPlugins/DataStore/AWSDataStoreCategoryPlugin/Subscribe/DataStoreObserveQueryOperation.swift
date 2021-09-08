//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

protocol DataStoreObserveQueryOperation {
    func resetState()
    func startObserveQuery()
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
///     - Generate new snapshot based on latest state of the items, with the items changed dedupped.
@available(iOS 13.0, *)
public class AWSDataStoreObserveQueryOperation<M: Model>: AsynchronousOperation, DataStoreObserveQueryOperation {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.AWSDataStoreObseverQueryOperation.serialQueue",
                                            target: DispatchQueue.global())
    private let itemsChangedPeriodicPublishTimeInSeconds: DispatchQueue.SchedulerTimeType.Stride = 2
    private let itemsChangedMaxSize = 1_000

    let modelType: M.Type
    let modelSchema: ModelSchema
    let predicate: QueryPredicate?
    let sortInput: [QuerySortDescriptor]?

    let storageEngine: StorageEngineBehavior
    var dataStorePublisher: ModelSubcriptionBehavior

    let observeQueryStarted: AtomicValue<Bool>
    let isSynced: AtomicValue<Bool>
    var currentItemsMap: [Model.Identifier: M]
    var itemsChangedSink: AnyCancellable?
    var dataStoreEventSink: AnyCancellable?

    /// Internal publisher for `ObserveQueryPublisher` to pass events back to subscribers
    let passthroughPublisher: PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>

    /// External subscribers subscribe to this publisher
    private let observeQueryPublisher: ObserveQueryPublisher<M>
    public var publisher: AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQueryPublisher.eraseToAnyPublisher()
    }

    init(modelType: M.Type,
         modelSchema: ModelSchema,
         predicate: QueryPredicate?,
         sortInput: [QuerySortDescriptor]?,
         storageEngine: StorageEngineBehavior,
         dataStorePublisher: ModelSubcriptionBehavior) {
        self.modelType = modelType
        self.modelSchema = modelSchema
        self.predicate = predicate
        self.sortInput = sortInput
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher

        self.observeQueryStarted = AtomicValue(initialValue: false)
        self.isSynced = AtomicValue(initialValue: false)
        self.currentItemsMap = [:]
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

        if let dataStoreEventSink = dataStoreEventSink {
            dataStoreEventSink.cancel()
        }
        passthroughPublisher.send(completion: .finished)
        super.cancel()
        finish()
    }

    func resetState() {
        serialQueue.async {
            if !self.observeQueryStarted.getAndSet(false) {
                return
            }
            self.log.verbose("Resetting state")
            self.isSynced.set(false)
            self.currentItemsMap.removeAll()
            self.itemsChangedSink = nil
            self.dataStoreEventSink = nil
        }
    }

    func startObserveQuery() {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            if self.observeQueryStarted.getAndSet(true) {
                return
            }
            self.log.verbose("Start ObserveQuery")
            self.dataStoreEventSink = Amplify.Hub.publisher(for: .dataStore)
                .sink(receiveValue: self.onDataStoreEvent(hubPayload:))
            self.subscribeToItemChanges()
            self.setInitialIsSyncedState()
            self.initialQuery()
        }
    }

    // MARK: - Initial IsSynced state

    func setInitialIsSyncedState() {
        // if the sync engine is active, then `.ready` event has already fired, set isSynced to true
        if let storageAdapter = storageEngine as? StorageEngine,
           let remoteSyncEngine = storageAdapter.syncEngine as? RemoteSyncEngine,
           case .syncEngineActive = remoteSyncEngine.stateMachine.state {
            isSynced.set(true)
        }
    }

    // MARK: - Observe DataStore events

    func onDataStoreEvent(hubPayload: HubPayload) {
        if isCancelled || isFinished {
            finish()
            return
        }

        if hubPayload.eventName == HubPayload.EventName.DataStore.modelSynced && !isSynced.get(),
           let modelSynced = hubPayload.data as? ModelSyncedEvent, modelSynced.modelName == modelSchema.name {
            isSynced.set(true)
            log.verbose("Received .modelSynced event")
        } else if hubPayload.eventName == HubPayload.EventName.DataStore.ready && !isSynced.get() {
            isSynced.set(true)
            log.verbose("Received .ready event")
        }
    }

    // MARK: - Query

    func initialQuery() {
        if isCancelled || isFinished {
            finish()
            return
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
                    storeCurrentItems(queriedModels: queriedModels)
                    generateQuerySnapshot()
                case .failure(let error):
                    self.passthroughPublisher.send(completion: .failure(error))
                    self.finish()
                    return
                }
            })
    }

    func storeCurrentItems(queriedModels: [M]) {
        for model in queriedModels {
            currentItemsMap.updateValue(model, forKey: model.id)
        }
    }

    // MARK: Observe item changes

    func subscribeToItemChanges() {
        itemsChangedSink = dataStorePublisher.publisher
            .filter(onItemChangedFilter(mutationEvent:))
            .collect(.byTimeOrCount(serialQueue, itemsChangedPeriodicPublishTimeInSeconds, itemsChangedMaxSize))
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemChanges(mutationEvents:))
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

    func onItemChanges(mutationEvents: [MutationEvent]) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            guard self.observeQueryStarted.get(), !mutationEvents.isEmpty else {
                return
            }

            self.generateQuerySnapshot(itemsChanged: mutationEvents)
        }
    }

    func generateQuerySnapshot(itemsChanged: [MutationEvent] = []) {
        updateCurrentItems(with: itemsChanged)
        var currentItems = Array(currentItemsMap.values.map { $0 }) as [M]
        if let sort = sortInput {
            sort.forEach { currentItems.sortModels(by: $0, modelSchema: modelSchema) }
        }
        publishSnapshot(ofItems: currentItems, isSynced: isSynced.get(), itemsChanged: itemsChanged)
    }

    func updateCurrentItems(with itemsChanged: [MutationEvent]) {
        for item in itemsChanged {
            do {
                let model = try item.decodeModel(as: modelType)
                if item.mutationType == MutationEvent.MutationType.delete.rawValue {
                    currentItemsMap.removeValue(forKey: model.id)
                } else {
                    currentItemsMap.updateValue(model, forKey: model.id)
                }
            } catch {
                log.error(error: error)
                continue
            }
        }
    }

    func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
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

    // MARK: - Helpers

    func publishSnapshot(ofItems items: [M], isSynced: Bool, itemsChanged: [MutationEvent]) {
        let querySnapshot = DataStoreQuerySnapshot(items: items,
                                                   isSynced: isSynced,
                                                   itemsChanged: dedup(mutationEvents: itemsChanged))
        log.verbose("items: \(querySnapshot.items.count) changed: \(querySnapshot.itemsChanged.count) isSynced: \(querySnapshot.isSynced)")
        passthroughPublisher.send(querySnapshot)
    }

    /// Remove duplicate MutationEvents based on the model identifier, keeping the latest one.
    func dedup(mutationEvents: [MutationEvent]) -> [MutationEvent] {
        var itemsChangedMap: [Model.Identifier: MutationEvent] = [:]
        for mutationEvent in mutationEvents {
            itemsChangedMap.updateValue(mutationEvent, forKey: mutationEvent.modelId)
        }
        return Array(itemsChangedMap.values.map { $0 })
    }
}

@available(iOS 13.0, *)
extension AWSDataStoreObserveQueryOperation: DefaultLogger { }
