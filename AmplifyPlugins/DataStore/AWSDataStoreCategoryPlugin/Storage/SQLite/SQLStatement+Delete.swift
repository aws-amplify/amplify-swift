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

    let schema: ModelSchema
    let conditionStatement: ConditionStatement?
    let namespace = "root"

    init(schema: ModelSchema, predicate: QueryPredicate? = nil) {
        self.schema = schema

        var conditionStatement: ConditionStatement?
        if let predicate = predicate {
            let statement = ConditionStatement(schema: schema,
                                               predicate: predicate,
                                               namespace: namespace[...])
            conditionStatement = statement
        }
        self.conditionStatement = conditionStatement
    }

    init(modelType: Model.Type, withId id: Model.Identifier) {
        self.init(schema: modelType.schema, predicate: field("id") == id)
    }

    init(model: Model) {
        self.init(schema: model.schema)
    }

    var stringValue: String {
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
