//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol StorageEngineAdapter: class, ModelStorageBehavior {

    func exists(_ modelType: Model.Type, withId id: Model.Identifier) throws -> Bool

    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>)

    func delete(_ modelType: Model.Type,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>)

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>)

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>]
}
