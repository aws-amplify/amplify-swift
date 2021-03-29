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

    init(modelSchema: ModelSchema, modelPredicate syncPredicate: @escaping QueryPredicateResolver) {
        self.modelSchema = modelSchema
        self.modelPredicate = {
            let predicate = syncPredicate()
            // Wrapping the predicate with a group AND enables
            // AppSync to optimize the request by performing a DynamoDB query instead of a scan.
            // If the provided syncPredicate is already a QueryPredicateGroup, this is not needed.
            // If the provided group is of type AND, the optimization will occur.
            // If the top level group is OR or NOT, the optimization is not possible anyway.
            if predicate as? QueryPredicateGroup != nil {
                return predicate
            } else if let predicate = predicate as? QueryPredicateConstant,
                      predicate == .all {
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
