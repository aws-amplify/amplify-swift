//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias QueryPredicateResolver = () -> QueryPredicate

public struct DataStoreSyncExpression {
    let modelSchema: ModelSchema
    let modelPredicate: QueryPredicateResolver

    init(modelSchema: ModelSchema, modelPredicate providedPredicate: @escaping QueryPredicateResolver) {
        self.modelSchema = modelSchema
        self.modelPredicate = {
            let predicate = providedPredicate()
            // wrap the provided predicate in an `and` group
            // in order to retrieve items using a query operation when possible
            if predicate as? QueryPredicateConstant != nil ||
               predicate as? QueryPredicateGroup != nil {
                return predicate
            }
            return QueryPredicateGroup(type: .and, predicates: [predicate])
        }
    }

    static public func syncExpression(_ modelSchema: ModelSchema,
                                      where predicate: @escaping QueryPredicateResolver) -> DataStoreSyncExpression {
        DataStoreSyncExpression(modelSchema: modelSchema, modelPredicate: predicate)
    }
}
