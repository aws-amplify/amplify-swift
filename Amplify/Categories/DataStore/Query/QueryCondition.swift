//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final public class QueryCondition {

    public let field: String
    public let predicate: QueryPredicate
    public private(set) var previous: QueryCondition?

    internal init(field: String,
                  predicate: QueryPredicate,
                  previous: QueryCondition? = nil) {
        self.field = field
        self.predicate = predicate
        self.previous = previous
    }

    func and(_ condition: QueryCondition) -> QueryCondition {
        previous = condition
        return condition
    }

    static func && (lhs: QueryCondition, rhs: QueryCondition) -> QueryCondition {
        rhs.previous = lhs
        return rhs
    }

}
