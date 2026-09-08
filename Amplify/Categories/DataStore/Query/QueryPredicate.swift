//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that indicates concrete types conforming to it can be used a predicate member.
/// - Note: `Sendable` because predicates are carried into the storage engine's async query paths.
public protocol QueryPredicate: Evaluable, Encodable, Sendable {}

public enum QueryPredicateGroupType: String, Encodable {
    case and
    case or
    case not
}

/// The `not` function is used to wrap a `QueryPredicate` in a `QueryPredicateGroup` of type `.not`.
/// - Parameter predicate: the `QueryPredicate` (either operation or group)
/// - Returns: `QueryPredicateGroup` of type `.not`
public func not(_ predicate: some QueryPredicate) -> QueryPredicateGroup {
    return QueryPredicateGroup(type: .not, predicates: [predicate])
}

/// The case `.all` is a predicate used as an argument to select all of a single modeltype. We
/// chose `.all` instead of `nil` because we didn't want to use the implicit nature of `nil` to
/// specify an action applies to an entire data set.
public enum QueryPredicateConstant: QueryPredicate, Encodable {
    case all
    public func evaluate(target: Model) -> Bool {
        return true
    }
}

/// - Note: `@unchecked Sendable`, and not `final`, so that anyone who subclassed this keeps compiling.
///
///   The conformance is a genuine assertion, not a checked fact. `and(_:)` and `or(_:)` mutate
///   `predicates` **in place and return `self`** when the group type already matches, so two tasks
///   composing onto the same group race on an array — and `predicates` is `public internal(set)`, so
///   external code reads it directly and a lock here would not cover those reads without turning it into
///   a computed property.
///
///   What makes this safe in practice is usage, not structure: a predicate is built up on one task and
///   then handed to a query. Sharing a part-built group across tasks is unsupported, and nothing in the
///   type enforces that. The exposure predates this annotation, which only stops the compiler asking.
public class QueryPredicateGroup: QueryPredicate, Encodable, @unchecked Sendable {
    public internal(set) var type: QueryPredicateGroupType
    public internal(set) var predicates: [QueryPredicate]

    public init(
        type: QueryPredicateGroupType = .and,
        predicates: [QueryPredicate] = []
    ) {
        self.type = type
        self.predicates = predicates
    }

    public func and(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .and = type {
            predicates.append(predicate)
            return self
        }
        return QueryPredicateGroup(type: .and, predicates: [self, predicate])
    }

    public func or(_ predicate: QueryPredicate) -> QueryPredicateGroup {
        if case .or = type {
            predicates.append(predicate)
            return self
        }
        return QueryPredicateGroup(type: .or, predicates: [self, predicate])
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

    // MARK: - Encodable conformance

    private enum CodingKeys: String, CodingKey {
        case type
        case predicates
    }

    struct AnyQueryPredicate: Encodable {
        private let _encode: (Encoder) throws -> Void

        init(_ base: QueryPredicate) {
            self._encode = base.encode
        }

        func encode(to encoder: Encoder) throws {
            try _encode(encoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)

        let anyPredicates = predicates.map(AnyQueryPredicate.init)
        try container.encode(anyPredicates, forKey: .predicates)
    }

}

/// - Note: `@unchecked Sendable` rather than `final`, for the same reason as ``QueryPredicateGroup``.
///   Both stored properties are immutable.
public class QueryPredicateOperation: QueryPredicate, Encodable, @unchecked Sendable {

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

    public func evaluate(target: Model) -> Bool {
        return self.operator.evaluate(target: target[field]?.flatMap { $0 })
    }
}
