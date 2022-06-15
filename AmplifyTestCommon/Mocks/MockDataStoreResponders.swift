//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockDataStoreCategoryPlugin {
    enum ResponderKeys {
        case saveModelListener
        case queryByIdListener
        case queryModelsListener
        case deleteByIdListener
        case deleteModelTypeListener
        case deleteModelListener
        case clearListener
        case startListener
        case stopListener
    }
}

typealias SaveModelResponder<M: Model> = MockResponder<
    (model: M, where: QueryPredicate?),
    DataStoreResult<M>?
>
typealias QueryByIdResponder<M: Model> = MockResponder<
    (modelType: M.Type, id: String),
    DataStoreResult<M?>?
>

typealias QueryModelsResponder<M: Model> = MockResponder<
    (modelType: M.Type, where: QueryPredicate?, sort: QuerySortInput?, paginate: QueryPaginationInput?),
    DataStoreResult<[M]>?
>

typealias DeleteByIdResponder<M: Model> = MockResponder<
    (modelType: M.Type, id: String),
    DataStoreResult<Void>?
>

typealias DeleteModelTypeResponder<M: Model> = MockResponder<
    (modelType: M.Type, where: QueryPredicate),
    DataStoreResult<Void>?
>

typealias DeleteModelResponder<M: Model> = MockResponder<
    (model: M, where: QueryPredicate?),
    DataStoreResult<Void>?
>

typealias ClearResponder = MockResponder<
    Void,
    DataStoreResult<Void>?
>

typealias StopResponder = MockResponder<
    Void,
    DataStoreResult<Void>?
>
