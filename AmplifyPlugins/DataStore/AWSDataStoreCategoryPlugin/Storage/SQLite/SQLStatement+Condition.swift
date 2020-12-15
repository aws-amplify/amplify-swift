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
    var groupType: QueryPredicateGroupType = .and
    let indentPrefix = "  "
    var indentSize = 1
    var groupOpened = false

    func translate(_ pred: QueryPredicate) {
        let indent = String(repeating: indentPrefix, count: indentSize)
        if let operation = pred as? QueryPredicateOperation {
            let logicalOperator = groupOpened ? "" : "\(groupType.rawValue) "
            let column = operation.operator.columnFor(field: operation.field,
                                                      namespace: namespace)
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
        } else if let constant = pred as? QueryPredicateConstant {
            if case .all = constant {
                sql.append("or 1 = 1")
            }
        }
    }
    translate(predicate)
    return (sql.joined(separator: "\n"), bindings)
}

private func translateQueryPredicate2(from modelSchema: ModelSchema,
                                      predicate: QueryPredicate,
                                      namespace: Substring? = nil) -> SQLPredicate {
    var sql: [String] = []
    var bindings: [Binding?] = []


    return (predicate.conditionSQL(namespace: namespace), bindings)
}

/// Represents a partial SQL statement with query conditions. This type can be used to
/// compose `insert`, `update`, `delete` and `select` statements with conditions.
struct ConditionStatement: SQLStatement {

    let modelSchema: ModelSchema
    let stringValue: String
    let stringValue2: String
    let variables: [Binding?]

    init(modelSchema: ModelSchema, predicate: QueryPredicate, namespace: Substring? = nil) {
        self.modelSchema = modelSchema

        let (sql, variables) = translateQueryPredicate(from: modelSchema,
                                                       predicate: predicate,
                                                       namespace: namespace)
        self.stringValue = sql
        let (sql2, variables2) = translateQueryPredicate2(from: modelSchema,
                                                          predicate: predicate,
                                                          namespace: namespace)
        self.stringValue2 = sql2
        self.variables = variables
    }
}
extension QueryPredicate {
    func conditionSQL(namespace: Substring? = nil,
                      indentPrefix: String = "  ",
                      indentSize: Int = 0) -> String {
        if let group = self as? QueryPredicateGroup {
            return group.conditionSQL(namespace: namespace,
                                      indentPrefix: indentPrefix,
                                      indentSize: indentSize)
        } else if let operation = self as? QueryPredicateOperation {
            return operation.conditionSQL(namespace: namespace,
                                          indentPrefix: indentPrefix,
                                          indentSize: indentSize)
        } else if let constant = self as? QueryPredicateConstant,
                  case .all = constant {
            return "or 1 = 1"
        }
        preconditionFailure("Failed \(String(describing: self))")
    }
}
extension QueryPredicateGroup {
    func conditionSQL(namespace: Substring? = nil,
                      indentPrefix: String,
                      indentSize: Int) -> String {
        let indent = String(repeating: indentPrefix, count: indentSize)
        let innerIndent = String(repeating: indentPrefix, count: indentSize + 1)
        let groupType = "\n\(innerIndent)\(type.rawValue) "
        let conditionSQL = Array(predicates.map { (predicate) -> String in
            return predicate.conditionSQL(namespace: namespace,
                                          indentPrefix: indentPrefix,
                                          indentSize: indentSize + 1)
        }).joined(separator: groupType)
        let condition = "\(indent)(\n\(innerIndent)\(conditionSQL)\n\(indent))"
        return indentSize == 0 ? condition : "\n\(condition)"

    }
}

extension QueryPredicateOperation {
    func conditionSQL(namespace: Substring? = nil,
                      indentPrefix: String,
                      indentSize: Int) -> String {
        let column = self.operator.columnFor(field: field,
                                             namespace: namespace)
        return column + " \(self.operator.sqlOperation)"
    }
}
