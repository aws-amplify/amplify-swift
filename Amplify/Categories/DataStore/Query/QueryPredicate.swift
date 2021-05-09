//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that indicates concrete types conforming to it can be used a predicate member.
public protocol QueryPredicate: Evaluable {}

/// <#Description#>
public enum QueryPredicateGroupType: String {
    case and
    case or
    case not
}

/// The `not` function is used to wrap a `QueryPredicate` in a `QueryPredicateGroup` of type `.not`.
/// - Parameter predicate: the `QueryPredicate` (either operation or group)
/// - Returns: `QueryPredicateGroup` of type `.not`
public func not<Predicate: QueryPredicate>(_ predicate: Predicate) -> QueryPredicateGroup {
    return QueryPredicateGroup(type: .not, predicates: [predicate])
}

/// The case `.all` is a predicate used as an argument to select all of a single modeltype. We
/// chose `.all` instead of `nil` because we didn't want to use the implicit nature of `nil` to
/// specify an action applies to an entire data set.
public enum QueryPredicateConstant: QueryPredicate {
    case all
    public func evaluate(target: Model) -> Bool {
        return true
    }
}

/// <#Description#>
public class QueryPredicateGroup: QueryPredicate {

    /// <#Description#>
    public internal(set) var type: QueryPredicateGroupType

    /// <#Description#>
    public internal(set) var predicates: [QueryPredicate]

    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - predicates: <#predicates description#>
    public init(type: QueryPredicateGroupType = .and,
                predicates: [QueryPredicate] = []) {
        self.type = type
        self.predicates = predicates
    }

    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    public func and(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .and = type {
            predicates.append(predicate)
            return self
        }
        return QueryPredicateGroup(type: .and, predicates: [self, predicate])
    }

    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    public func or(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .or = type {
            predicates.append(predicate)
            return self
        }
        return QueryPredicateGroup(type: .or, predicates: [self, predicate])
    }

    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func && (lhs: QueryPredicateGroup, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.and(rhs)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func || (lhs: QueryPredicateGroup, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.or(rhs)
    }

    /// <#Description#>
    /// - Parameter rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static prefix func ! (rhs: QueryPredicateGroup) -> QueryPredicateGroup {
        return not(rhs)
    }

    /// <#Description#>
    /// - Parameter target: <#target description#>
    /// - Returns: <#description#>
    public func evaluate(target: Model) -> Bool {
        switch type {
        case .or:
            for predicate in predicates {
                if predicate.evaluate(target: target) {
                    return true
                }
            }
            return false
        case .and:
            for predicate in predicates {
                if !predicate.evaluate(target: target) {
                    return false
                }
            }
            return true
        case .not:
            let predicate = predicates[0]
            return !predicate.evaluate(target: target)
        }
    }
}

/// <#Description#>
public class QueryPredicateOperation: QueryPredicate {

    /// <#Description#>
    public let field: String

    /// <#Description#>
    public let `operator`: QueryOperator

    /// <#Description#>
    /// - Parameters:
    ///   - field: <#field description#>
    ///   - operator: <#operator description#>
    public init(field: String, operator: QueryOperator) {
        self.field = field
        self.operator = `operator`
    }

    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    public func and(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        let group = QueryPredicateGroup(type: .and, predicates: [self, predicate])
        return group
    }

    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    public func or(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        let group = QueryPredicateGroup(type: .or, predicates: [self, predicate])
        return group
    }

    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func && (lhs: QueryPredicateOperation, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.and(rhs)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func || (lhs: QueryPredicateOperation, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.or(rhs)
    }

    /// <#Description#>
    /// - Parameter rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static prefix func ! (rhs: QueryPredicateOperation) -> QueryPredicateGroup {
        return not(rhs)
    }

    /// <#Description#>
    /// - Parameter target: <#target description#>
    /// - Returns: <#description#>
    public func evaluate(target: Model) -> Bool {
        guard let fieldValue = target[field] else {
            return false
        }
        guard let value = fieldValue else {
            return false
        }

        if let booleanValue = value as? Bool {
            return self.operator.evaluate(target: booleanValue)
        }

        if let doubleValue = value as? Double {
            return self.operator.evaluate(target: doubleValue)
        }

        if let intValue = value as? Int {
            return self.operator.evaluate(target: intValue)
        }
        if let timeValue = value as? Temporal.Time {
            return self.operator.evaluate(target: timeValue)
        }

        return self.operator.evaluate(target: value)
    }
}
