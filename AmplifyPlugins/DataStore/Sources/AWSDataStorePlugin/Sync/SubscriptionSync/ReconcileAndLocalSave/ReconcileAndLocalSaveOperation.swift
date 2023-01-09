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

/// Reconciles an incoming model mutation with the stored model. If there is no conflict (e.g., the incoming model has
/// a later version than the stored model), then write the new data to the store.
class ReconcileAndLocalSaveOperation: AsynchronousOperation {

    /// Disambiguation for the version of the model incoming from the remote API
    typealias RemoteModel = MutationSync<AnyModel>

    /// Disambiguation for the sync metadata for the model stored in local datastore
    typealias LocalMetadata = MutationSyncMetadata

    /// Disambiguation for the version of the model that was applied to the local datastore. In the case of a create or
    /// update mutation, this represents the saved model. In the case of a delete mutation, this is the data that was
    /// sent from the remote API as part of the mutation.
    typealias AppliedModel = MutationSync<AnyModel>

    let id: UUID = UUID()
    private let workQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndLocalSaveOperation",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?
    private let stateMachine: StateMachine<State, Action>
    private let remoteModels: [RemoteModel]
    private let modelSchema: ModelSchema
    private let stopwatch: Stopwatch
    private var stateMachineSink: AnyCancellable?
    private var cancellables: Set<AnyCancellable>
    private let mutationEventPublisher: PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>
    public var publisher: AnyPublisher<ReconcileAndLocalSaveOperationEvent, DataStoreError> {
        return mutationEventPublisher.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         remoteModels: [RemoteModel],
         storageAdapter: StorageEngineAdapter?,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.modelSchema = modelSchema
        self.remoteModels = remoteModels
        self.storageAdapter = storageAdapter
        self.stopwatch = Stopwatch()
        self.stateMachine = stateMachine ?? StateMachine(initialState: .waiting,
                                                         resolver: Resolver.resolve(currentState:action:))
        self.mutationEventPublisher = PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>()

        self.cancellables = Set<AnyCancellable>()
        super.init()

        self.stateMachineSink = self.stateMachine
            .$state
            .sink { [weak self] newState in
                guard let self = self else {
                    return
                }
                self.log.verbose("New state: \(newState)")
                self.workQueue.async {
                    self.respond(to: newState)
                }
            }
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            return
        }

        stopwatch.start()
        stateMachine.notify(action: .started(remoteModels))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .reconciling(let remoteModels):
            reconcile(remoteModels: remoteModels)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)
            notifyFinished()

        case .finished:
            // Maybe we have to notify the Hub?
            notifyFinished()
        }
    }

    // MARK: - Responder methods

    func reconcile(remoteModels: [RemoteModel]) {
        guard !isCancelled else {
            log.info("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            let error = DataStoreError.nilStorageAdapter()
            notifyDropped(count: remoteModels.count, error: error)
            stateMachine.notify(action: .errored(error))
            return
        }

        guard !remoteModels.isEmpty else {
            stateMachine.notify(action: .reconciled)
            return
        }

        let remoteModelIds = remoteModels.map { $0.model.identifier }

        do {
            try storageAdapter.transaction {
                queryPendingMutations(forModelIds: remoteModelIds)
                    .subscribe(on: workQueue)
                    .flatMap { mutationEvents -> Future<([RemoteModel], [LocalMetadata]), DataStoreError> in
                        let remoteModelsToApply = self.reconcile(remoteModels, pendingMutations: mutationEvents)
                        return self.queryLocalMetadata(remoteModelsToApply)
                    }
                    .flatMap { (remoteModelsToApply, localMetadatas) -> Future<Void, DataStoreError> in
                        let dispositions = self.getDispositions(for: remoteModelsToApply,
                                                                localMetadatas: localMetadatas)
                        return self.applyRemoteModelsDispositions(dispositions)
                    }
                    .sink(
                        receiveCompletion: {
                            if case .failure(let error) = $0 {
                                self.stateMachine.notify(action: .errored(error))
                            }
                        },
                        receiveValue: {
                            self.stateMachine.notify(action: .reconciled)
                        }
                    )
                    .store(in: &cancellables)
            }
        } catch let dataStoreError as DataStoreError {
            stateMachine.notify(action: .errored(dataStoreError))
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            stateMachine.notify(action: .errored(dataStoreError))
        }
    }

    func queryPendingMutations(forModelIds modelIds: [String]) -> Future<[MutationEvent], DataStoreError> {
        Future<[MutationEvent], DataStoreError> { promise in
            var result: Result<[MutationEvent], DataStoreError> = .failure(Self.unfulfilledDataStoreError())
            guard !self.isCancelled else {
                self.log.info("\(#function) - cancelled, aborting")
                result = .success([])
                promise(result)
                return
            }
            guard let storageAdapter = self.storageAdapter else {
                let error = DataStoreError.nilStorageAdapter()
                self.notifyDropped(count: modelIds.count, error: error)
                result = .failure(error)
                promise(result)
                return
            }

            guard !modelIds.isEmpty else {
                result = .success([])
                promise(result)
                return
            }

            MutationEvent.pendingMutationEvents(for: modelIds,
                                                storageAdapter: storageAdapter) { queryResult in
                switch queryResult {
                case .failure(let dataStoreError):
                    self.notifyDropped(count: modelIds.count, error: dataStoreError)
                    result = .failure(dataStoreError)
                case .success(let mutationEvents):
                    result = .success(mutationEvents)
                }
                promise(result)
            }
        }
    }

    func reconcile(_ remoteModels: [RemoteModel], pendingMutations: [MutationEvent]) -> [RemoteModel] {
        guard !remoteModels.isEmpty else {
            return []
        }

        let remoteModelsToApply = RemoteSyncReconciler.filter(remoteModels,
                                                              pendingMutations: pendingMutations)
        notifyDropped(count: remoteModels.count - remoteModelsToApply.count)
        return remoteModelsToApply
    }

    func queryLocalMetadata(_ remoteModels: [RemoteModel]) -> Future<([RemoteModel], [LocalMetadata]), DataStoreError> {
        Future<([RemoteModel], [LocalMetadata]), DataStoreError> { promise in
            var result: Result<([RemoteModel], [LocalMetadata]), DataStoreError> =
                .failure(Self.unfulfilledDataStoreError())
            defer {
                promise(result)
            }
            guard !self.isCancelled else {
                self.log.info("\(#function) - cancelled, aborting")
                result = .success(([], []))
                return
            }
            guard let storageAdapter = self.storageAdapter else {
                let error = DataStoreError.nilStorageAdapter()
                self.notifyDropped(count: remoteModels.count, error: error)
                result = .failure(error)
                return
            }

            guard !remoteModels.isEmpty else {
                result = .success(([], []))
                return
            }

            do {
                let localMetadatas = try storageAdapter.queryMutationSyncMetadata(
                    for: remoteModels.map { $0.model.identifier },
                       modelName: self.modelSchema.name)
                result = .success((remoteModels, localMetadatas))
            } catch {
                let error = DataStoreError(error: error)
                self.notifyDropped(count: remoteModels.count, error: error)
                result = .failure(error)
                return
            }
        }
    }

    func getDispositions(for remoteModels: [RemoteModel],
                         localMetadatas: [LocalMetadata]) -> [RemoteSyncReconciler.Disposition] {
        guard !remoteModels.isEmpty else {
            return []
        }

        let dispositions = RemoteSyncReconciler.getDispositions(remoteModels,
                                                                localMetadatas: localMetadatas)
        notifyDropped(count: remoteModels.count - dispositions.count)
        return dispositions
    }

    // TODO: refactor - move each the publisher constructions to its own utility method for readability of the
    // `switch` and a single method that you can invoke in the `map`
    func applyRemoteModelsDispositions(
        _ dispositions: [RemoteSyncReconciler.Disposition]) -> Future<Void, DataStoreError> {
        Future<Void, DataStoreError> { promise in
            var result: Result<Void, DataStoreError> = .failure(Self.unfulfilledDataStoreError())
            defer {
                promise(result)
            }
            guard !self.isCancelled else {
                self.log.info("\(#function) - cancelled, aborting")
                result = .successfulVoid
                return
            }
            guard let storageAdapter = self.storageAdapter else {
                let error = DataStoreError.nilStorageAdapter()
                self.notifyDropped(count: dispositions.count, error: error)
                result = .failure(error)
                return
            }

            guard !dispositions.isEmpty else {
                result = .successfulVoid
                return
            }

            let publishers = dispositions.map { disposition ->
                Publishers.FlatMap<Future<Void, DataStoreError>,
                                   Future<ReconcileAndLocalSaveOperation.ApplyRemoteModelResult, DataStoreError>> in

                switch disposition {
                case .create(let remoteModel):
                    let publisher = self.save(storageAdapter: storageAdapter,
                                              remoteModel: remoteModel)
                        .flatMap { applyResult in
                            self.saveMetadata(storageAdapter: storageAdapter,
                                              applyResult: applyResult,
                                              mutationType: .create)
                        }
                    return publisher
                case .update(let remoteModel):
                    let publisher = self.save(storageAdapter: storageAdapter,
                                              remoteModel: remoteModel)
                        .flatMap { applyResult in
                            self.saveMetadata(storageAdapter: storageAdapter,
                                              applyResult: applyResult,
                                              mutationType: .update)
                        }
                    return publisher
                case .delete(let remoteModel):
                    let publisher = self.delete(storageAdapter: storageAdapter,
                                                remoteModel: remoteModel)
                        .flatMap { applyResult in
                            self.saveMetadata(storageAdapter: storageAdapter,
                                              applyResult: applyResult,
                                              mutationType: .delete)
                        }
                    return publisher
                }
            }

            Publishers.MergeMany(publishers)
                .collect()
                .sink(
                    receiveCompletion: {
                        if case .failure(let error) = $0 {
                            result = .failure(error)
                        }
                    },
                    receiveValue: { _ in
                        result = .successfulVoid
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    enum ApplyRemoteModelResult {
        case applied(RemoteModel)
        case dropped
    }

    private func delete(storageAdapter: StorageEngineAdapter,
                        remoteModel: RemoteModel) -> Future<ApplyRemoteModelResult, DataStoreError> {
        Future<ApplyRemoteModelResult, DataStoreError> { promise in
            guard let modelType = ModelRegistry.modelType(from: self.modelSchema.name) else {
                let error = DataStoreError.invalidModelName(self.modelSchema.name)
                promise(.failure(error))
                return
            }

            storageAdapter.delete(untypedModelType: modelType,
                                  modelSchema: self.modelSchema,
                                  withIdentifier: remoteModel.model.identifier(schema: self.modelSchema),
                                  condition: nil) { response in
                switch response {
                case .failure(let dataStoreError):
                    self.notifyDropped(error: dataStoreError)
                    if storageAdapter.shouldIgnoreError(error: dataStoreError) {
                        promise(.success(.dropped))
                    } else {
                        promise(.failure(dataStoreError))
                    }
                case .success:
                    promise(.success(.applied(remoteModel)))
                }
            }
        }
    }

    private func save(storageAdapter: StorageEngineAdapter,
                      remoteModel: RemoteModel) -> Future<ApplyRemoteModelResult, DataStoreError> {
        Future<ApplyRemoteModelResult, DataStoreError> { promise in
            storageAdapter.save(untypedModel: remoteModel.model.instance) { response in
                switch response {
                case .failure(let dataStoreError):
                    self.notifyDropped(error: dataStoreError)
                    if storageAdapter.shouldIgnoreError(error: dataStoreError) {
                        promise(.success(.dropped))
                    } else {
                        promise(.failure(dataStoreError))
                    }
                case .success(let savedModel):
                    let anyModel: AnyModel
                    do {
                        anyModel = try savedModel.eraseToAnyModel()
                    } catch {
                        let dataStoreError = DataStoreError(error: error)
                        self.notifyDropped(error: dataStoreError)
                        promise(.failure(dataStoreError))
                        return
                    }
                    let inProcessModel = MutationSync(model: anyModel, syncMetadata: remoteModel.syncMetadata)
                    promise(.success(.applied(inProcessModel)))
                }
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              applyResult: ApplyRemoteModelResult,
                              mutationType: MutationEvent.MutationType) -> Future<Void, DataStoreError> {
        Future<Void, DataStoreError> { promise in
            guard case let .applied(inProcessModel) = applyResult else {
                promise(.successfulVoid)
                return
            }

            storageAdapter.save(inProcessModel.syncMetadata, condition: nil, eagerLoad: true) { result in
                switch result {
                case .failure(let dataStoreError):
                    self.notifyDropped(error: dataStoreError)
                    promise(.failure(dataStoreError))
                case .success(let syncMetadata):
                    let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                    self.notify(savedModel: appliedModel, mutationType: mutationType)
                    promise(.successfulVoid)
                }
            }
        }
    }

    private func notifyDropped(count: Int = 1, error: DataStoreError? = nil) {
        for _ in 0 ..< count {
            mutationEventPublisher.send(.mutationEventDropped(modelName: modelSchema.name, error: error))
        }
    }

    private func notify(savedModel: AppliedModel,
                        mutationType: MutationEvent.MutationType) {
        let version = savedModel.syncMetadata.version

        // TODO: Dispatch/notify error if we can't erase to any model? Would imply an error in JSON decoding,
        // which shouldn't be possible this late in the process. Possibly notify global conflict/error handler?
        guard let json = try? savedModel.model.instance.toJSON() else {
            log.error("Could not notify mutation event")
            return
        }
        let modelIdentifier = savedModel.model.instance.identifier(schema: modelSchema).stringValue
        let mutationEvent = MutationEvent(modelId: modelIdentifier,
                                          modelName: modelSchema.name,
                                          json: json,
                                          mutationType: mutationType,
                                          version: version)

        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncReceived,
                                 data: mutationEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)

        mutationEventPublisher.send(.mutationEvent(mutationEvent))
    }

    private func notifyFinished() {
        if log.logLevel == .debug {
            log.debug("total time: \(stopwatch.stop())s")
        }
        mutationEventPublisher.send(completion: .finished)
        finish()
    }

    private static func unfulfilledDataStoreError(name: String = #function) -> DataStoreError {
        .unknown("\(name) did not fulfill promise", AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
    }
}

extension ReconcileAndLocalSaveOperation: DefaultLogger { }

enum ReconcileAndLocalSaveOperationEvent {
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String, error: DataStoreError? = nil)
}
