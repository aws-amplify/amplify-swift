//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Implements a SQLite query translator that turn persistence operations into `insert`, `update`,
/// `delete` and `select` SQL statements based on `Model` types.
class SQLiteQueryTranslator: QueryTranslator {

    typealias Value = Binding?

    func translateToCreateTable(from modelType: Model.Type) -> Query<Binding?> {
        let schema = modelType.schema
        let name = schema.name
        var statement = "create table if not exists \(name) (\n"

        let columns = schema.allFields.columns()
        let foreignKeys = schema.allFields.foreignKeys()

        for (index, column) in columns.enumerated() {
            statement += "  \"\(column.sqlName)\" \(column.sqlType.rawValue)"
            if column.isPrimaryKey {
                statement += " primary key"
            }
            if column.isRequired {
                statement += " not null"
            }

            let isNotLastColumn = index < columns.endIndex - 1
            if isNotLastColumn {
                statement += ",\n"
            }
        }

        let hasForeignKeys = !foreignKeys.isEmpty
        if hasForeignKeys {
            statement += ",\n"
        }

        for foreignKey in foreignKeys {
            statement += "  foreign key(\"\(foreignKey.sqlName)\") "
            let connectedModel = foreignKey.requiredConnectedModel
            let connectedId = connectedModel.schema.primaryKey
            statement += "references \(connectedModel.schema.name)(\"\(connectedId.sqlName)\")"
        }

        statement += "\n);"
        return Query(statement)
    }

    func translateToDelete(from model: Model) -> Query<Binding?> {
        preconditionFailure("Not implemented for SQLite yet")
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
                          predicate: QueryPredicate? = nil) -> Query<Binding?> {
        let schema = modelType.schema
        let fields = schema.allFields.columns()
        let tableName = schema.name
        var columns = fields.map { field -> String in
            return field.columnName(forNamespace: "root") + " " + field.columnAlias()
        }

        // eager load many-to-one relationships (simple inner join)
        var joinStatements: [String] = []
        for foreignKey in schema.allFields.foreignKeys() {
            let connectedModelType = foreignKey.requiredConnectedModel
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

        if let predicate = predicate {
            let conditionQuery = translateQueryPredicate(from: modelType, predicate: predicate)
            return Query("""
            \(sql)
            where 1 = 1
              \(conditionQuery.string)
            """, arguments: conditionQuery.arguments)
        }

        return Query(sql)
    }

    internal func translateQueryPredicate(from modelType: Model.Type,
                                          predicate: QueryPredicate) -> Query<Binding?> {
        var sql: [String] = []
        var bindings: [Binding?] = []
        var groupType: QueryPredicateGroupType = .and
        let indentPrefix = "  "
        var indentSize = 1
        var groupOpened = false
        func translate(_ pred: QueryPredicate) {
            let indent = String(repeating: indentPrefix, count: indentSize)
            if let operation = pred as? QueryPredicateOperation {
                let logicalOperator = groupOpened ? "" : "\(groupType.rawValue) "
                let column = operation.operator.columnFor(field: operation.field)
                sql.append("\(indent)\(logicalOperator)\(column) \(operation.operator.sqlOperation)")
                bindings.append(contentsOf: operation.operator.bindings)
                groupOpened = false
            } else if let group = pred as? QueryPredicateGroup {
                var shouldClose = false
                groupOpened = group.type != groupType
                if groupOpened {
                    sql.append("\(indent)\(groupType.rawValue) (")
                    groupType = group.type
                    indentSize += 1
                    shouldClose = true
                }
                group.predicates.forEach { translate($0) }
                if shouldClose {
                    indentSize -= 1
                    sql.append("\(indent))")
                }
            }
        }
        translate(predicate)
        return Query(sql.joined(separator: "\n"), arguments: bindings)
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
