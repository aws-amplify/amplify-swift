//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `delete` SQL statement that is optionally composed by a `ConditionStatement`.
struct DeleteStatement: SQLStatement {

    let modelType: Model.Type
    let conditionStatement: ConditionStatement?
    let namespace = "root"

    init(modelType: Model.Type, predicate: QueryPredicate? = nil) {
        self.modelType = modelType

        var conditionStatement: ConditionStatement?
        if let predicate = predicate {
            let statement = ConditionStatement(modelType: modelType,
                                               predicate: predicate,
                                               namespace: namespace[...])
            conditionStatement = statement
        }
        self.conditionStatement = conditionStatement
    }

    init(modelType: Model.Type, withId id: Model.Identifier) {
        self.init(modelType: modelType, predicate: field("id") == id)
    }

    init(model: Model) {
        self.init(modelType: type(of: model))
    }

    var stringValue: String {
        let schema = modelType.schema
        let sql = """
        delete from \(schema.name) as \(namespace)
        """

        if let conditionStatement = conditionStatement {
            return """
            \(sql)
            where 1 = 1
            \(conditionStatement.stringValue)
            """
        }
        return sql
    }

    var variables: [Binding?] {
        return conditionStatement?.variables ?? []
    }

}
