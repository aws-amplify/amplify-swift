//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `select` SQL statement associated with a `Model` instance and
/// optionally composed by a `ConditionStatement`.
struct SelectStatement: SQLStatement {

    let modelType: Model.Type
    let conditionStatement: ConditionStatement?
    let paginationInput: QueryPaginationInput?

    // TODO remove this once sorting support is added to DataStore
    // Used by plugin to order and limit results for system table queries
    let additionalStatements: String?
    let namespace = "root"

    init(from modelType: Model.Type,
         predicate: QueryPredicate? = nil,
         paginationInput: QueryPaginationInput? = nil,
         additionalStatements: String? = nil) {
        self.modelType = modelType

        var conditionStatement: ConditionStatement?
        if let predicate = predicate {
            let statement = ConditionStatement(modelType: modelType,
                                               predicate: predicate,
                                               namespace: namespace[...])
            conditionStatement = statement
        }
        self.conditionStatement = conditionStatement
        self.paginationInput = paginationInput
        self.additionalStatements = additionalStatements
    }

    var stringValue: String {
        let schema = modelType.schema
        let fields = schema.columns
        let tableName = schema.name
        var columns = fields.map { field -> String in
            return field.columnName(forNamespace: namespace) + " " + field.columnAlias()
        }

        // eager load many-to-one/one-to-one relationships
        var joinStatements: [String] = []
        for foreignKey in schema.foreignKeys {
            let associatedModelType = foreignKey.requiredAssociatedModel
            let associatedSchema = associatedModelType.schema
            let associatedTableName = associatedModelType.schema.name

            // columns
            let alias = foreignKey.name
            let associatedColumn = associatedSchema.primaryKey.columnName(forNamespace: alias)
            let foreignKeyName = foreignKey.columnName(forNamespace: "root")

            // append columns from relationships
            columns += associatedSchema.columns.map { field -> String in
                return field.columnName(forNamespace: alias) + " " + field.columnAlias(forNamespace: alias)
            }

            let joinType = foreignKey.isRequired ? "inner" : "left outer"

            joinStatements.append("""
            \(joinType) join \(associatedTableName) as \(alias)
              on \(associatedColumn) = \(foreignKeyName)
            """)
        }

        var sql = """
        select
          \(joinedAsSelectedColumns(columns))
        from \(tableName) as root
        \(joinStatements.joined(separator: "\n"))
        """.trimmingCharacters(in: .whitespacesAndNewlines)

        if let conditionStatement = conditionStatement {
            sql = """
            \(sql)
            where 1 = 1
            \(conditionStatement.stringValue)
            """
        }

        if let additionalStatements = additionalStatements {
            sql = """
            \(sql)
            \(additionalStatements)
            """
        }

        if let paginationInput = paginationInput {
            sql = """
            \(sql)
            \(paginationInput.sqlStatement)
            """
        }

        return sql
    }

    var variables: [Binding?] {
        return conditionStatement?.variables ?? []
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
