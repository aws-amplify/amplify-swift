//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

protocol StorageEngineAdapter: class, ModelStorageBehavior {

    // MARK: - Async APIs
    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<M?>)

    func delete(untypedModelType modelType: Model.Type,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>)

    func delete<M: Model>(_ modelType: M.Type,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>)

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: QuerySortInput?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>)

    // MARK: - Synchronous APIs

    func exists(_ modelType: Model.Type,
                withId id: Model.Identifier,
                predicate: QueryPredicate?) throws -> Bool

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: Model.Identifier) throws -> MutationSyncMetadata?

    func queryModelSyncMetadata(for modelType: Model.Type) throws -> ModelSyncMetadata?

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func clear(completion: @escaping DataStoreCallback<Void>)
}
