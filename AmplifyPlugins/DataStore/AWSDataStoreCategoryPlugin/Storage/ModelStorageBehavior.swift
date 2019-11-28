//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol ModelStorageBehavior {
    func setUp(models: [Model.Type]) throws

    func save<M: Model>(_ model: M, completion: @escaping DataStoreCallback<M>)

    func delete(_ modelType: Model.Type,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>)

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         completion: DataStoreCallback<[M]>)

}
