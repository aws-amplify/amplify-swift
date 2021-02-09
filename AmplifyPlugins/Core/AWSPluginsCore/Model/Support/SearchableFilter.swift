//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol SearchPredicate { }

extension CodingKey where Self: ModelKey {
    /// Adds autocompletion to build a search predicate, ie. `Post.keys.search(.match("word"))`
    public func search(_ operator: SearchPredicateOperator) -> SearchPredicateOperation {
        return SearchPredicateOperation(field: stringValue,
                                        operator: `operator`)
    }
}

/// Cases match exactly the `SearchableFilterInput`'s from an AppSync Search API provisioned using the `@searchable`
/// directive.
public enum SearchPredicateOperator {
    case equal(_ value: Persistable)
    case exists(_ value: Bool)
    case greaterThan(_ value: Persistable)
    case greaterOrEqual(_ value: Persistable)
    case lessThan(_ value: Persistable)
    case lessOrEqual(_ value: Persistable)
    case match(_ value: String)
    case matchPhrase(_ value: String)
    case matchPhrasePrefix(_ value: String)
    case notEqual(_ value: Persistable)
    case range(start: Persistable, end: Persistable)
    case regexp(_ value: String)
    case wildcard(_ value: String)
}

public class SearchPredicateGroup: SearchPredicate {
    public internal(set) var type: QueryPredicateGroupType
    public internal(set) var predicates: [SearchPredicate]

    public init(type: QueryPredicateGroupType = .and,
                predicates: [SearchPredicate] = []) {
        self.type = type
        self.predicates = predicates
    }

    public func and(_ predicate: SearchPredicate) -> SearchPredicateGroup {
        if case .and = type {
            predicates.append(predicate)
            return self
        }
        return SearchPredicateGroup(type: .and, predicates: [self, predicate])
    }

    public func or(_ predicate: SearchPredicate) -> SearchPredicateGroup {
        if case .or = type {
            predicates.append(predicate)
            return self
        }
        return SearchPredicateGroup(type: .or, predicates: [self, predicate])
    }

    public static func && (lhs: SearchPredicateGroup, rhs: SearchPredicate) -> SearchPredicateGroup {
        return lhs.and(rhs)
    }

    public static func || (lhs: SearchPredicateGroup, rhs: SearchPredicate) -> SearchPredicateGroup {
        return lhs.or(rhs)
    }

    public static prefix func ! (rhs: SearchPredicateGroup) -> SearchPredicateGroup {
        return SearchPredicateGroup(type: .not, predicates: [rhs])
    }
}

public class SearchPredicateOperation: SearchPredicate {
    public let field: String
    public let `operator`: SearchPredicateOperator

    public init(field: String, operator: SearchPredicateOperator) {
        self.field = field
        self.operator = `operator`
    }

    public func and(_ predicate: SearchPredicate) -> SearchPredicateGroup {
        let group = SearchPredicateGroup(type: .and, predicates: [self, predicate])
        return group
    }

    public func or(_ predicate: SearchPredicate) -> SearchPredicateGroup {
        let group = SearchPredicateGroup(type: .or, predicates: [self, predicate])
        return group
    }

    public static func && (lhs: SearchPredicateOperation, rhs: SearchPredicate) -> SearchPredicateGroup {
        return lhs.and(rhs)
    }

    public static func || (lhs: SearchPredicateOperation, rhs: SearchPredicate) -> SearchPredicateGroup {
        return lhs.or(rhs)
    }

    public static prefix func ! (rhs: SearchPredicateOperation) -> SearchPredicateGroup {
        return SearchPredicateGroup(type: .not, predicates: [rhs])
    }
}

extension SearchPredicate {
    public func graphQLFilter(for modelSchema: ModelSchema?) -> GraphQLFilter {
        if let operation = self as? SearchPredicateOperation {
            return operation.graphQLFilter(for: modelSchema)
        } else if let group = self as? SearchPredicateGroup {
            return group.graphQLFilter(for: modelSchema)
        }

        preconditionFailure(
            "Could not find SearchPredicateOperation or SearchPredicateGroup for \(String(describing: self))")
    }
}

extension SearchPredicateOperation: GraphQLFilterConvertible {
    func graphQLFilter(for modelSchema: ModelSchema?) -> GraphQLFilter {
        let filterValue = [self.operator.graphQLOperator: self.operator.value]
        guard let modelSchema = modelSchema else {
            return [field: filterValue]
        }
        return [columnName(modelSchema): filterValue]
    }

    func columnName(_ modelSchema: ModelSchema) -> String {
        guard let modelField = modelSchema.field(withName: field) else {
            return field
        }
        let defaultFieldName = modelSchema.name.camelCased() + field.pascalCased() + "Id"
        switch modelField.association {
        case .belongsTo(_, let targetName):
            return targetName ?? defaultFieldName
        case .hasOne(_, let targetName):
            return targetName ?? defaultFieldName
        default:
            return field
        }
    }
}

extension SearchPredicateGroup: GraphQLFilterConvertible {

    func graphQLFilter(for modelSchema: ModelSchema?) -> GraphQLFilter {
        let logicalOperator = type.rawValue
        switch type {
        case .and, .or:
            var graphQLPredicateOperation = [logicalOperator: [Any]()]
            predicates.forEach { predicate in
                graphQLPredicateOperation[logicalOperator]?.append(predicate.graphQLFilter(for: modelSchema))
            }
            return graphQLPredicateOperation
        case .not:
            if let predicate = predicates.first {
                return [logicalOperator: predicate.graphQLFilter(for: modelSchema)]
            } else {
                preconditionFailure("Missing predicate for \(String(describing: self)) with type: \(type)")
            }
        }
    }
}

extension SearchPredicateOperator {
    var graphQLOperator: String {
        switch self {
        case .equal:
            return "eq"
        case .exists:
            return "exists"
        case .greaterThan:
            return "gt"
        case .greaterOrEqual:
            return "gte"
        case .lessThan:
            return "le"
        case .lessOrEqual:
            return "lte"
        case .match:
            return "match"
        case .matchPhrase:
            return "matchPhrase"
        case .matchPhrasePrefix:
            return "matchPhrasePrefix"
        case .notEqual:
            return "ne"
        case .range:
            return "range"
        case .regexp:
            return "regexp"
        case .wildcard:
            return "wildcard"
        }
    }

    var value: Any? {
        switch self {
        case .equal(let value),
             .greaterThan(let value),
             .greaterOrEqual(let value),
             .lessThan(let value),
             .lessOrEqual(let value),
             .notEqual(let value):
            return value.graphQLValue()
        case .exists(let value):
            return value.graphQLValue()
        case .match(let value),
            .matchPhrase(let value),
            .matchPhrasePrefix(let value),
            .regexp(let value),
            .wildcard(let value):
            return value
        case .range(let start, let end):
            return [start.graphQLValue(), end.graphQLValue()]
        }
    }
}
