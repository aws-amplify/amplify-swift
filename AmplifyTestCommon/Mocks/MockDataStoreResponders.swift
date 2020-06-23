//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockDataStoreCategoryPlugin {
    struct Responders {
        var clear: ClearResponder?
        var deleteById: DeleteByIdResponder?
        var deleteByInstance: DeleteByInstanceResponder?
        var queryById: QueryByIdResponder?
        var queryByPredicate: QueryByPredicateResponder?
        var save: SaveResponder?
    }
}

typealias ClearResponder = () -> DataStoreResult<Void>

typealias DeleteByIdResponder = (Model.Type, String) -> DataStoreResult<Void>

typealias DeleteByInstanceResponder = (Model, QueryPredicate?) -> DataStoreResult<Void>

typealias QueryByIdResponder = (Model.Type, String) -> DataStoreResult<Model?>

typealias QueryByPredicateResponder = (
    Model.Type,
    QueryPredicate?,
    QueryPaginationInput?
) -> DataStoreResult<[Model]>

typealias SaveResponder = (Model, QueryPredicate?) -> DataStoreResult<Model>
