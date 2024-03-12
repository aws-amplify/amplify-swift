//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
private func translateQueryPredicate(
    from modelSchema: ModelSchema,
    predicate: QueryPredicate,
    namespace: Substring? = nil
) -> SQLPredicate {
    let indentPrefix = " "
    let indentSize = 2

    func translate(_ predicate: QueryPredicateOperation, indentationLevel: Int) -> (String, [Binding?]) {
        func padding(_ level: Int) -> String {
            String(repeating: indentPrefix, count: indentSize * level)
        }

        func statement(_ sqls: [String], predicate: QueryPredicateOperation) -> String {
            switch sqls.count {
            case 0: return ""
            case 1: return "\(padding(indentationLevel))\(predicate.operator) \(sqls.joined())"
            default:
                let statements = sqls.joined(separator: "\n\(padding(indentationLevel + 1))\(predicate.operator) ")
                return """
                (
                \(padding(indentationLevel + 1))\(statements)
                \(padding(indentationLevel)))
                """
            }
        }

        switch predicate {
        case let .operation(field, op):
            let column = resolveColumn(field)
            return (op.sqlOperation(column: column), op.bindings)
        case .and(let predicates),
             .or(let predicates):
            let sqls = predicates.map { translate($0, indentationLevel: indentationLevel + 1) }
            return (
                statement(sqls.map(\.0), predicate: predicate),
                sqls.map(\.1).flatMap { $0 }
            )
        case let .not(predicate):
            let sql = translate(predicate, indentationLevel: indentationLevel + 1)
            return (
                statement([sql.0], predicate: predicate),
                sql.1
            )
        case .true:
            return ("1 = 1", [])
        case .false:
            return ("1 = 0", [])
        }
    }

    func resolveColumn(_ field: String) -> String {
        let modelField = modelSchema.field(withName: field)
        if let namespace = namespace, let modelField = modelField {
            return modelField.columnName(forNamespace: String(namespace))
        } else if let modelField = modelField {
            return modelField.columnName()
        } else if let namespace = namespace {
            return String(namespace).quoted() + "." + field.quoted()
        }
        return field.quoted()
    }

    func deduplicate(_ predicate: QueryPredicateOperation) -> QueryPredicateOperation {
        func rewritePredicate(_ predicate: QueryPredicateOperation) -> QueryPredicateOperation {
            switch predicate {
            case let .operation(field, op):
                if case .attributeExists(let bool) = op {
                    return bool ? .operation(field, .notEqual(nil))
                                : .operation(field, .equals(nil))
                }
                return predicate
            case .and, .or:
                return deduplicate(predicate)
            default:
                return predicate
            }
        }

        switch predicate {
        case let .and(predicates):
            let optimizedPredicates = predicates.map(rewritePredicate(_:)).reduce([]) { result, predicate in
                result.contains(where: { predicate == $0 }) ? result : result + [predicate]
            }
            return optimizedPredicates.count == 1
                ? optimizedPredicates.first!
                : .and(optimizedPredicates)
        case let .or(predicates):
            let optimizedPredicates = predicates.map(rewritePredicate(_:)).reduce([]) { result, predicate in
                result.contains(where: { predicate == $0 }) ? result : result + [predicate]
            }
            return optimizedPredicates.count == 1
                ? optimizedPredicates.first!
                : .or(optimizedPredicates)
        default:
            return predicate
        }
    }

    // the very first `and` is always prepended, using -1 for if statement checking
    // the very first `and` is to connect `where` clause with translated QueryPredicate

    guard let predicate = predicate as? QueryPredicateOperation else {
        return ("", [])
    }
    return translate(QueryPredicateOperation.and([deduplicate(predicate)]), indentationLevel: 0)
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
