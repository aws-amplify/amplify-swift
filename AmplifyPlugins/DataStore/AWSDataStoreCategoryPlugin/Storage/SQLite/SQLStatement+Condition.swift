//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

typealias SQLPredicate = (String, [Binding?])

/// Utility function that translates a `QueryPredicate` to well-formatted SQL conditions.
/// It walks all nodes of a predicate tree and output the appropriate SQL statement.
///
/// - Parameters:
///   - modelSchema: the model schema of the `Model`
///   - predicate: the query predicate
/// - Returns: a tuple containing the SQL string and the associated values
private func translateQueryPredicate(from modelSchema: ModelSchema,
                                     predicate: QueryPredicate,
                                     namespace: Substring? = nil) -> SQLPredicate {
    var sql: [String] = []
    var bindings: [Binding?] = []
    let indentPrefix = "  "
    var indentSize = 1
    var groupOpened = false

    func translate(_ pred: QueryPredicate, opAhead: Bool, groupType: QueryPredicateGroupType) {
        let indent = String(repeating: indentPrefix, count: indentSize)
        if let operation = pred as? QueryPredicateOperation {
            let logicalOperator = groupOpened ? "" : "\(groupType.rawValue) "
            let column = operation.operator.columnFor(field: operation.field,
                                                      namespace: namespace)
            if opAhead {
                sql.append("\(indent)\(logicalOperator)\(column) \(operation.operator.sqlOperation)")
            } else {
                sql.append("\(indent)\(column) \(operation.operator.sqlOperation)")
            }

            bindings.append(contentsOf: operation.operator.bindings)
            groupOpened = false
        } else if let group = pred as? QueryPredicateGroup {
            var shouldClose = false

            if opAhead {
                sql.append("\(indent)\(groupType.rawValue) (")
            } else {
                sql.append("\(indent)(")
            }

            indentSize += 1
            shouldClose = true
            var predicateIndex = 0
            group.predicates.forEach {
                translate($0, opAhead: predicateIndex != 0, groupType: group.type)
                predicateIndex += 1
            }
            if shouldClose {
                indentSize -= 1
                sql.append("\(indent))")
            }
        } else if let constant = pred as? QueryPredicateConstant {
            if case .all = constant {
                sql.append("or 1 = 1")
            }
        }
    }
    translate(predicate, opAhead: true, groupType: .and)
    return (sql.joined(separator: "\n"), bindings)
}

/// Represents a partial SQL statement with query conditions. This type can be used to
/// compose `insert`, `update`, `delete` and `select` statements with conditions.
struct ConditionStatement: SQLStatement {

    let modelSchema: ModelSchema
    let stringValue: String
    let variables: [Binding?]

    init(modelSchema: ModelSchema, predicate: QueryPredicate, namespace: Substring? = nil) {
        self.modelSchema = modelSchema

        let (sql, variables) = translateQueryPredicate(from: modelSchema,
                                                       predicate: predicate,
                                                       namespace: namespace)
        self.stringValue = sql
        self.variables = variables
    }

}
