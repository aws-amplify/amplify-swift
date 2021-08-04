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
@available(iOS 13.0, *)
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
            stateMachine.notify(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        guard !remoteModels.isEmpty else {
            stateMachine.notify(action: .reconciled)
            return
        }

        let remoteModelIds = remoteModels.map { $0.model.id }

        do {
            try storageAdapter.transaction {
                queryPendingMutations(forModelIds: remoteModelIds)
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
        } catch let dataSotoreError as DataStoreError {
            stateMachine.notify(action: .errored(dataSotoreError))
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            stateMachine.notify(action: .errored(dataStoreError))
        }
    }

    func queryPendingMutations(forModelIds modelIds: [Model.Identifier]) -> Future<[MutationEvent], DataStoreError> {
        Future<[MutationEvent], DataStoreError> { promise in
            var result: Result<[MutationEvent], DataStoreError> = .failure(Self.unfulfilledDataStoreError())
            defer {
                promise(result)
            }
            guard !self.isCancelled else {
                self.log.info("\(#function) - cancelled, aborting")
                result = .success([])
                return
            }
            guard let storageAdapter = self.storageAdapter else {
                result = .failure(DataStoreError.nilStorageAdapter())
                return
            }

            guard !modelIds.isEmpty else {
                result = .success([])
                return
            }

            MutationEvent.pendingMutationEvents(for: modelIds,
                                                storageAdapter: storageAdapter) { queryResult in
                switch queryResult {
                case .failure(let dataStoreError):
                    result = .failure(dataStoreError)
                case .success(let mutationEvents):
                    result = .success(mutationEvents)
                }
            }
        }
    }

    func reconcile(_ remoteModels: [RemoteModel], pendingMutations: [MutationEvent]) -> [RemoteModel] {
        guard let remoteModel = remoteModels.first else {
            return []
        }

        let remoteModelsToApply = RemoteSyncReconciler.filter(remoteModels,
                                                              pendingMutations: pendingMutations)

        for _ in 0 ..< (remoteModels.count - remoteModelsToApply.count) {
            notifyDropped(modelName: remoteModel.model.modelName)
        }

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
                result = .failure(DataStoreError.nilStorageAdapter())
                return
            }

            guard !remoteModels.isEmpty else {
                result = .success(([], []))
                return
            }

            do {
                let localMetadatas = try storageAdapter.queryMutationSyncMetadata(
                    for: remoteModels.map { $0.model.id })
                result = .success((remoteModels, localMetadatas))
            } catch {
                result = .failure(DataStoreError(error: error))
                return
            }
        }
    }

    func getDispositions(for remoteModels: [RemoteModel],
                         localMetadatas: [LocalMetadata]) -> [RemoteSyncReconciler.Disposition] {
        guard let remoteModel = remoteModels.first else {
            return []
        }

        let dispositions = RemoteSyncReconciler.getDispositions(remoteModels,
                                                                localMetadatas: localMetadatas)
        for _ in 0 ..< (remoteModels.count - dispositions.count) {
            notifyDropped(modelName: remoteModel.model.modelName)
        }

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
                result = .failure(DataStoreError.nilStorageAdapter())
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
                                  withId: remoteModel.model.id,
                                  predicate: nil) { response in
                switch response {
                case .failure(let dataStoreError):
                    if storageAdapter.shouldIgnoreError(error: dataStoreError) {
                        self.notifyDropped(modelName: remoteModel.model.modelName)
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
                    if storageAdapter.shouldIgnoreError(error: dataStoreError) {
                        self.notifyDropped(modelName: remoteModel.model.modelName)
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

            storageAdapter.save(inProcessModel.syncMetadata, condition: nil) { result in
                switch result {
                case .failure(let dataStoreError):
                    promise(.failure(dataStoreError))
                case .success(let syncMetadata):
                    let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                    self.notify(savedModel: appliedModel, mutationType: mutationType)
                    promise(.successfulVoid)
                }
            }
        }
    }

    private func notifyDropped(modelName: String) {
        mutationEventPublisher.send(.mutationEventDropped(modelName: modelName))
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
        let mutationEvent = MutationEvent(modelId: savedModel.model.instance.id,
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

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }

enum ReconcileAndLocalSaveOperationEvent {
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String)
}
