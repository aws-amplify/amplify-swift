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

typealias SaveModelResponder<M: Model> =
    (M, QueryPredicate?) -> DataStoreResult<M>?

typealias QueryByIdResponder<M: Model> =
    (M.Type, String) -> DataStoreResult<M?>?

typealias QueryModelsResponder<M: Model> = (
    M.Type,
    QueryPredicate?,
    QuerySortInput?,
    QueryPaginationInput?
) -> DataStoreResult<[M]>?


typealias DeleteByIdResponder<M: Model> =
    (String) -> DataStoreResult<Void>?

typealias DeleteModelTypeResponder<M: Model> =
    (QueryPredicate) -> DataStoreResult<Void>?


typealias DeleteModelResponder<M: Model> =
    (M, QueryPredicate?) -> DataStoreResult<Void>?

typealias ClearResponder =
    () -> DataStoreResult<Void>?


typealias StopResponder =
    () -> DataStoreResult<Void>?
