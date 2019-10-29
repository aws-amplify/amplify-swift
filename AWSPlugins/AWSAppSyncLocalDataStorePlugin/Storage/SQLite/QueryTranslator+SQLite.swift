//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

class SQLiteQueryTranslator: QueryTranslator {

    typealias Value = Binding?

    func translateToDelete(from model: Model) -> Query<Binding?> {
        preconditionFailure("Not implemented for SQLite")
    }

    func translateToInsert(from model: Model) -> Query<Binding?> {
        let modelType = type(of: model)
        let schema = modelType.schema
        let fields = schema.allFields.columns()
        let columns = fields.map { $0.columnName() }
        var statement = "insert into \(schema.name) "
        statement += "(\(columns.joined(separator: ", ")))\n"

        let valuePlaceholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        statement += "values (\(valuePlaceholders))"

        let values = model.sqlValues(for: fields)
        return Query(statement, arguments: values)
    }

    func translateToUpdate(from model: Model) -> Query<Binding?> {
        preconditionFailure("Not implemented for SQLite")
    }

    func translateToQuery(from modelType: Model.Type,
                          condition: QueryCondition? = nil) -> Query<Binding?> {
        let schema = modelType.schema
        let fields = schema.allFields.columns()
        let tableName = schema.name
        var columns = fields.map { field -> String in
            return field.columnName(forNamespace: "root") + " " + field.columnAlias()
        }

        // eager load many-to-one relationships (simple inner join)
        var joinStatements: [String] = []
        for foreignKey in schema.allFields.foreignKeys() {
            let connectedModelType = foreignKey.connectedModel!
            let connectedSchema = connectedModelType.schema
            let connectedTableName = connectedModelType.schema.name

            // columns
            let alias = foreignKey.name
            let connectedColumn = connectedSchema.primaryKey.columnName(forNamespace: alias)
            let foreignKeyName = foreignKey.columnName(forNamespace: "root")

            // append columns from relationships
            columns += connectedSchema.allFields.columns().map { field -> String in
                return field.columnName(forNamespace: alias) + " " + field.columnAlias(forNamespace: alias)
            }

            joinStatements.append("""
            inner join \(connectedTableName) as \(alias)
              on \(connectedColumn) = \(foreignKeyName)
            """)
        }

        let sql = """
        select
          \(joinedAsSelectedColumns(columns))
        from \(tableName) as root
        \(joinStatements.joined(separator: "\n"))
        """

        if let condition = condition {
            let conditionQuery = translateQueryCondition(from: modelType, conditions: condition)
            return Query("""
            \(sql)
            where 1 = 1
              \(conditionQuery.string)
            """, arguments: conditionQuery.arguments)
        }

        return Query(sql)
    }

    internal func translateQueryCondition(from modelType: Model.Type,
                                          conditions: QueryCondition) -> Query<Binding?> {
        var statements: [String] = []
        var values: [Binding?] = []
        var currentCondition: QueryCondition? = conditions

        while let condition = currentCondition {
            let predicate = condition.predicate
            let column = predicate.columnFor(field: condition.field)
            let operation = predicate.operation

            statements.insert("and \(column) \(operation)", at: 0)
            values.insert(contentsOf: predicate.bindings, at: 0)

            currentCondition = condition.previous
        }
        return Query(statements.joined(separator: "\n  "), arguments: values)
    }
}

// MARK: - Helpers

/// Join a list of table columns joined and formatted for readability.
///
/// - Parameter columns the list of column names
/// - Parameter perLine max numbers of columns per line
/// - Returns: a list of columns that can be used in `select` SQL statements
internal func joinedAsSelectedColumns(_ columns: [String], perLine: Int = 3) -> String {
    return columns.enumerated().reduce("") { partial, entry in
        let spacer = entry.offset == 0 || entry.offset % perLine == 0 ? "\n  " : " "
        let isFirstOrLast = entry.offset == 0 || entry.offset >= columns.count
        let separator = isFirstOrLast ? "" : ",\(spacer)"
        return partial + separator + entry.element
    }
}
