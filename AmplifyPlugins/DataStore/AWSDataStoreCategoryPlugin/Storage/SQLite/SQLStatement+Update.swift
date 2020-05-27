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

    let modelType: Model.Type
    let conditionStatement: ConditionStatement?

    private let model: Model

    init(model: Model, condition: QueryPredicate? = nil) {
        self.modelType = type(of: model)
        self.model = model

        var conditionStatement: ConditionStatement?
        if let condition = condition {
            let statement = ConditionStatement(modelType: modelType,
                                               predicate: condition)
            conditionStatement = statement
        }

        self.conditionStatement = conditionStatement
    }

    var stringValue: String {
        let schema = modelType.schema
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
        var bindings = model.sqlValues(for: updateColumns)
        bindings.append(model.id)
        if let conditionStatement = conditionStatement {
            bindings.append(contentsOf: conditionStatement.variables)
        }
        return bindings
    }

    private var updateColumns: [ModelField] {
        modelType.schema.columns.filter { !$0.isPrimaryKey }
    }
}
