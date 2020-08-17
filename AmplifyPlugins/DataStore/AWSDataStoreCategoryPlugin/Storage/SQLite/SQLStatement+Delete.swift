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

    let modelSchema: ModelSchema
    let conditionStatement: ConditionStatement?
    let namespace = "root"

    init(modelSchema: ModelSchema, predicate: QueryPredicate? = nil) {
        self.modelSchema = modelSchema

        var conditionStatement: ConditionStatement?
        if let predicate = predicate {
            let statement = ConditionStatement(modelSchema: modelSchema,
                                               predicate: predicate,
                                               namespace: namespace[...])
            conditionStatement = statement
        }
        self.conditionStatement = conditionStatement
    }

    init(modelSchema: ModelSchema, withId id: Model.Identifier) {
        self.init(modelSchema: modelSchema, predicate: field("id") == id)
    }

    init(model: Model) {
        self.init(modelSchema: model.schema)
    }

    var stringValue: String {
        let sql = """
        delete from \(modelSchema.name) as \(namespace)
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
