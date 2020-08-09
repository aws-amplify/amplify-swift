//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `update` SQL statement.
struct UpdateStatement: SQLStatement {

    let schema: ModelSchema
    let conditionStatement: ConditionStatement?

    private let model: Model

    init(model: Model, condition: QueryPredicate? = nil) {
        self.schema = model.schema
        self.model = model

        var conditionStatement: ConditionStatement?
        if let condition = condition {
            let statement = ConditionStatement(schema: schema,
                                               predicate: condition)
            conditionStatement = statement
        }

        self.conditionStatement = conditionStatement
    }

    var stringValue: String {
        let columns = updateColumns.map { $0.columnName() }

        let columnsStatement = columns.map { column in
            "  \(column) = ?"
        }

        var sql = """
        update \(schema.name)
        set
        \(columnsStatement.joined(separator: ",\n"))
        where \(schema.primaryKey.columnName()) = ?
        """

        if let conditionStatement = conditionStatement {
            sql = """
            \(sql)
            \(conditionStatement.stringValue)
            """
        }

        return sql
    }

    var variables: [Binding?] {
        var bindings = model.sqlValues(for: updateColumns, schema: schema)
        bindings.append(model.id)
        if let conditionStatement = conditionStatement {
            bindings.append(contentsOf: conditionStatement.variables)
        }
        return bindings
    }

    private var updateColumns: [ModelField] {
        schema.columns.filter { !$0.isPrimaryKey }
    }
}
