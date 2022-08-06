//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

protocol StorageEngineAdapter: AnyObject, ModelStorageBehavior, ModelStorageErrorBehavior, StorageEngineMigrationAdapter {

    static var maxNumberOfPredicates: Int { get }

    // MARK: - Async APIs
    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          condition: QueryPredicate?,
                          completion: @escaping DataStoreCallback<M?>)

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: Model.Identifier,
                condition: QueryPredicate?,
                completion: DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          filter: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>)

    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)
    
    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate?) async -> DataStoreResult<[Model]>

    // MARK: - Synchronous APIs

    @available(*, deprecated, message: "Use exists(_:withIdentifier:predicate)")
    func exists(_ modelSchema: ModelSchema,
                withId id: Model.Identifier,
                predicate: QueryPredicate?) throws -> Bool

    func exists(_ modelSchema: ModelSchema,
                withIdentifier id: ModelIdentifierProtocol,
                predicate: QueryPredicate?) throws -> Bool

    func queryMutationSync(for models: [Model], modelName: String) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: Model.Identifier, modelName: String) throws -> MutationSyncMetadata?

    func queryMutationSyncMetadata(for modelIds: [Model.Identifier], modelName: String) throws -> [MutationSyncMetadata]

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata?

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func clear(completion: @escaping DataStoreCallback<Void>)
}

protocol StorageEngineMigrationAdapter {

    @discardableResult func removeStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func createStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func emptyStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func renameStore(from: ModelSchema, toModelSchema: ModelSchema) throws -> String
}

extension StorageEngineAdapter {

    func delete<M: Model>(_ modelType: M.Type,
                          filter predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        delete(modelType, modelSchema: modelType.schema, filter: predicate, completion: completion)
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          condition: QueryPredicate? = nil,
                          completion: @escaping DataStoreCallback<M?>) {
        delete(modelType, modelSchema: modelType.schema, withId: id, condition: condition, completion: completion)
    }

    func delete(untypedModelType modelType: Model.Type,
                withId id: Model.Identifier,
                condition: QueryPredicate? = nil,
                completion: DataStoreCallback<Void>) {
        delete(untypedModelType: modelType,
               modelSchema: modelType.schema,
               withId: id,
               condition: condition,
               completion: completion)
    }
}
