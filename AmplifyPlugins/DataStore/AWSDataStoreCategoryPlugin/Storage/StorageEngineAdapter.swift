//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

protocol StorageEngineAdapter: AnyObject, ModelStorageBehavior, ModelStorageErrorBehavior {

    static var maxNumberOfPredicates: Int { get }

    // MARK: - Async APIs
    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          predicate: QueryPredicate?,
                          completion: @escaping DataStoreCallback<M?>)

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: Model.Identifier,
                predicate: QueryPredicate?,
                completion: DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>)

    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)

    // MARK: - Synchronous APIs

    func exists(_ modelSchema: ModelSchema,
                withId id: Model.Identifier,
                predicate: QueryPredicate?) throws -> Bool

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: Model.Identifier) throws -> MutationSyncMetadata?

    func queryMutationSyncMetadata(for modelIds: [Model.Identifier]) throws -> [MutationSyncMetadata]

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata?

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func clear(completion: @escaping DataStoreCallback<Void>)
}

extension StorageEngineAdapter {

    func delete<M: Model>(_ modelType: M.Type,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        delete(modelType, modelSchema: modelType.schema, predicate: predicate, completion: completion)
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          predicate: QueryPredicate? = nil,
                          completion: @escaping DataStoreCallback<M?>) {
        delete(modelType, modelSchema: modelType.schema, withId: id, predicate: predicate, completion: completion)
    }

    func delete(untypedModelType modelType: Model.Type,
                withId id: Model.Identifier,
                predicate: QueryPredicate? = nil,
                completion: DataStoreCallback<Void>) {
        delete(untypedModelType: modelType,
               modelSchema: modelType.schema,
               withId: id,
               predicate: predicate,
               completion: completion)
    }
}
