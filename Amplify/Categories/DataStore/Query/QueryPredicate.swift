//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that indicates concrete types conforming to it can be used a predicate member.
public protocol QueryPredicate: Codable {
    static var metatype: QueryPredicateType { get }
}

/// List of possible `QueryPredicate` types
public enum QueryPredicateType: String, Codable {
    case group
    case constant
    case operation

    var metatype: QueryPredicate.Type {
        switch self {
        case .group:
            return QueryPredicateGroup.self
        case .constant:
            return QueryPredicateConstant.self
        case .operation:
            return QueryPredicateOperation.self
        }
    }
}

public enum QueryPredicateGroupType: String, Codable {
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
public enum QueryPredicateConstant: String, QueryPredicate {
    public static var metatype: QueryPredicateType = .constant

    case all
}

public class QueryPredicateGroup: QueryPredicate {
    public static var metatype: QueryPredicateType = .group

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

    /// Provide conformance to `Codable`

    enum CodingKeys: String, CodingKey {
        case type
        case predicates
    }

    /// Decode `type` and `predicates`. Array of predicates are first decoded using `AnyQueryPredicate` wrapper, and
    /// then the inner `QueryPredicate` is retrieved.
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(QueryPredicateGroupType.self, forKey: .type)
        self.predicates = try container.decode([AnyQueryPredicate].self, forKey: .predicates).map { $0.base }
    }

    /// Encode `type` and `predicates`. Array of predicates are encoded as an array of `AnyQueryPredicate`'s.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(predicates.map(AnyQueryPredicate.init), forKey: .predicates)
    }
}

public class QueryPredicateOperation: QueryPredicate {
    public static var metatype: QueryPredicateType = .operation

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
