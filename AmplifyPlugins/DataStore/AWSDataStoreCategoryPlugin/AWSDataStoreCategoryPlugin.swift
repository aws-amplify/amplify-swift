//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

final public class AWSDataStoreCategoryPlugin: DataStoreCategoryPlugin {

    public var key: PluginKey = "AWSDataStoreCategoryPlugin"

    /// `true` if any models are syncable. Resolved during configuration phase
    var isSyncEnabled: Bool

    /// The Publisher that sends mutation events to subscribers
    private let dataStorePublisher: DataStorePublisher

    /// The local storage provider. Resolved during configuration phase
    private var storageEngine: StorageEngineBehavior!

    /// No-argument init that uses defaults for all providers
    public init() {
        self.isSyncEnabled = false
        self.dataStorePublisher = DataStorePublisher()
    }

    /// Internal initializer for testing
    init(storageEngine: StorageEngineBehavior,
         dataStorePublisher: DataStorePublisher) {
        self.isSyncEnabled = false
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher
    }

    /// By the time this method gets called, DataStore will already have invoked
    /// `DataStoreModelRegistration.registerModels`, so we can inspect those models to derive isSyncEnabled, and pass
    /// them to `StorageEngine.setUp(models:)`
    public func configure(using configuration: Any) throws {
        resolveSyncEnabled()
        try resolveStorageEngine()
        try storageEngine.setUp(models: ModelRegistry.models)
    }

    private func resolveSyncEnabled() {
        if #available(iOS 13.0, *) {
            self.isSyncEnabled = ModelRegistry.models.contains { $0.schema.isSyncable }
        } else {
            isSyncEnabled = false
        }
    }

    private func resolveStorageEngine() throws {
        guard storageEngine == nil else {
            return
        }

        storageEngine = try StorageEngine(isSyncEnabled: isSyncEnabled)
    }
}

extension AWSDataStoreCategoryPlugin: DataStoreBaseBehavior {

    public func save<M: Model>(_ model: M,
                               completion: @escaping DataStoreCallback<M>) {
        let publishingCompletion: DataStoreCallback<M> = { result in
            switch result {
            case .result(let model):
                // TODO: Differentiate between save & update
                // TODO: Handle errors from mutation event creation
                if let mutationEvent = try? MutationEvent(model: model, mutationType: .create) {
                    self.dataStorePublisher.send(input: mutationEvent)
                }
            case .error:
                break
            }

            completion(result)
        }

        storageEngine.save(model, completion: publishingCompletion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                completion: DataStoreCallback<M?>) {
        let predicate: QueryPredicateFactory = { field("id") == id }
        query(modelType, where: predicate) {
            switch $0 {
            case .result(let models):
                if models.count > 1 {
                    completion(.error(.nonUniqueResult(model: modelType.schema.name)))
                } else {
                    completion(.result(models.first))
                }
            case .error(let error):
                completion(.failure(causedBy: error))
            }
        }
    }

    public func query<M: Model>(_ modelType: M.Type,
                                where predicateFactory: QueryPredicateFactory?,
                                completion: DataStoreCallback<[M]>) {
        storageEngine.query(modelType,
                            predicate: predicateFactory?(),
                            completion: completion)
    }

    public func delete<M: Model>(_ model: M,
                                 completion: DataStoreCallback<Void>) {
        let publishingCompletion: DataStoreCallback<Void> = { result in
            switch result {
            case .result:
                // TODO: Handle errors from mutation event creation
                if let mutationEvent = try? MutationEvent(model: model, mutationType: .delete) {
                    self.dataStorePublisher.send(input: mutationEvent)
                }
            case .error:
                break
            }
            completion(result)
        }

        delete(type(of: model),
               withId: model.id,
               completion: publishingCompletion)
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: String,
                                 completion: DataStoreCallback<Void>) {
        storageEngine.delete(modelType,
                             withId: id,
                             completion: completion)
    }

    public func reset(onComplete: @escaping (() -> Void)) {
        //        storageEngine.shutdown()
        onComplete()
    }

}

extension AWSDataStoreCategoryPlugin: DataStoreSubscribeBehavior {
    @available(iOS 13.0, *)
    public func publisher<M: Model>(for modelType: M.Type)
        -> AnyPublisher<MutationEvent, DataStoreError> {
            return dataStorePublisher.publisher(for: modelType)
    }
}
