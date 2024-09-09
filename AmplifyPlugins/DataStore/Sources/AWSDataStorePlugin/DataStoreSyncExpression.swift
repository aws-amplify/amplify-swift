//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public typealias QueryPredicateResolver = () -> QueryPredicate

public struct DataStoreSyncExpression {
    let modelSchema: ModelSchema
    let modelPredicate: QueryPredicateResolver

    public static func syncExpression(
        _ modelSchema: ModelSchema,
        where predicate: @escaping QueryPredicateResolver
    ) -> DataStoreSyncExpression {
        DataStoreSyncExpression(modelSchema: modelSchema, modelPredicate: predicate)
    }
}
