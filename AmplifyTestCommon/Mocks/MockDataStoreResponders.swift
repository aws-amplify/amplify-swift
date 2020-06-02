//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockDataStoreCategoryPlugin {
    enum ResponderKeys {
        case clear
        case deleteById
        case deleteByInstance
        case queryById
        case queryByPredicate
        case save
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
