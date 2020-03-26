//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that indicates concrete types conforming to it can be used a predicate member.
public protocol QueryPredicate {}

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
}

public class QueryPredicateGroup: QueryPredicate {
    public internal(set) var type: QueryPredicateGroupType
    public internal(set) var predicates: [QueryPredicate]

    public init(type: QueryPredicateGroupType = .and,
                predicates: [QueryPredicate] = []) {
        self.type = type
        self.predicates = predicates
    }

    public func and(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .and = type {
            predicates.append(predicate)
            return self
        }
        let group = QueryPredicateGroup(type: .and, predicates: [predicate])
        predicates.append(group)
        return self
    }

    public func or(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .or = type {
            predicates.append(predicate)
            return self
        }
        let group = QueryPredicateGroup(type: .or, predicates: [predicate])
        predicates.append(group)
        return self
    }

    public static func && (lhs: QueryPredicateGroup, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.and(rhs)
    }

    public static func || (lhs: QueryPredicateGroup, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.or(rhs)
    }

    public static prefix func ! (rhs: QueryPredicateGroup) -> QueryPredicateGroup {
        return not(rhs)
    }
}

public class QueryPredicateOperation: QueryPredicate {

    public let field: String
    public let `operator`: QueryOperator

    public init(field: String, operator: QueryOperator) {
        self.field = field
        self.operator = `operator`
    }

    public func and(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        let group = QueryPredicateGroup(type: .and, predicates: [self, predicate])
        return group
    }

    public func or(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        let group = QueryPredicateGroup(type: .or, predicates: [self, predicate])
        return group
    }

    public static func && (lhs: QueryPredicateOperation, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.and(rhs)
    }

    public static func || (lhs: QueryPredicateOperation, rhs: QueryPredicate) -> QueryPredicateGroup {
        return lhs.or(rhs)
    }

    public static prefix func ! (rhs: QueryPredicateOperation) -> QueryPredicateGroup {
        return not(rhs)
    }
}
