//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

protocol StorageEngineAdapter: class, ModelStorageBehavior {

    func exists(_ modelType: Model.Type, withId id: Model.Identifier) throws -> Bool

    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>)

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<Void>)

    func delete(untypedModelType modelType: Model.Type,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>)

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         additionalStatements: String?,
                         completion: DataStoreCallback<[M]>)

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: Model.Identifier) throws -> MutationSyncMetadata?

}
