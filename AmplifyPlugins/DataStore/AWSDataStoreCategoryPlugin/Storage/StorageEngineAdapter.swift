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

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>)

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)

    // MARK: - Synchronous APIs

    func exists(_ modelSchema: ModelSchema,
                withId id: Model.Identifier,
                predicate: QueryPredicate?) throws -> Bool

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: Model.Identifier) throws -> MutationSyncMetadata?

    func queryModelSyncMetadata(for modelType: Model.Type) throws -> ModelSyncMetadata?

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func clear(completion: @escaping DataStoreCallback<Void>)
}
