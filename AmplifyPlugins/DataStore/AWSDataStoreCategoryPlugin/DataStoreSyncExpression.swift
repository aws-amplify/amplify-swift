//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias QueryPredicateResolver = () -> QueryPredicate

public struct DataStoreSyncExpression {
    let modelType: Model.Type
    let modelPredicate: QueryPredicateResolver

    static public func syncExpression(_ modelType: Model.Type,
                                      where predicate: @escaping QueryPredicateResolver) -> DataStoreSyncExpression {
        return DataStoreSyncExpression(modelType: modelType, modelPredicate: predicate)
    }
}
