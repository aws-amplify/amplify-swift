//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

public indirect enum QueryPredicateOperation {
    case `true`
    case `false`
    case operation(String, QueryOperator)
    case and([QueryPredicateOperation])
    case or([QueryPredicateOperation])
    case not(QueryPredicateOperation)

    public var `operator`: String {
        switch self {
        case .and: return "and"
        case .or: return "or"
        case .not: return "not"
        default: return ""
        }
    }
}

public class QueryPredicateConstant {
    public static let all = QueryPredicateOperation.true
}

extension QueryPredicateOperation {
    public func and(_ rhs: QueryPredicateOperation) -> QueryPredicateOperation {
        switch (self, rhs) {
        case let (.and(lhsPredicates), .and(rhsPredicates)):
            return .and(lhsPredicates + rhsPredicates)
        case let (.and(predicates), _):
            return .and(predicates + [rhs])
        case let (_, .and(predicates)):
            return .and([self] + predicates)
        default:
            return .and([self, rhs])
        }
    }

    public func or(_ rhs: QueryPredicateOperation) -> QueryPredicateOperation {
        switch (self, rhs) {
        case let (.or(lhsPredicates), .or(rhsPredicates)):
            return .or(lhsPredicates + rhsPredicates)
        case let (.or(predicates), _):
            return .or(predicates + [rhs])
        case let (_, .or(predicates)):
            return .or([self] + predicates)
        default:
            return .or([self, rhs])
        }
    }

    public func not() -> QueryPredicateOperation {
        .not(self)
    }
}

extension QueryPredicateOperation {
    public static func && (
        lhs: QueryPredicateOperation,
        rhs: QueryPredicateOperation
    ) -> QueryPredicateOperation {
        lhs.and(rhs)
    }

    public static func || (
        lhs: QueryPredicateOperation,
        rhs: QueryPredicateOperation
    ) -> QueryPredicateOperation {
        lhs.or(rhs)
    }

    public static prefix func ! (rhs: QueryPredicateOperation) -> QueryPredicateOperation {
        not(rhs)
    }
}

extension QueryPredicateOperation: QueryPredicate {
    public func evaluate(target: Model) -> Bool {
        switch self {
        case .true: return true
        case .false: return false
        case let .operation(field, op):
            return op.evaluate(target: target[field]?.flatMap { $0 })
        case let .and(predicates):
            return predicates.reduce(true, { $0 && $1.evaluate(target: target) })
        case let .or(predicates):
            return predicates.reduce(false, { $0 || $1.evaluate(target: target) })
        case let .not(op):
            return !op.evaluate(target: target)
        }
    }
}

extension QueryPredicateOperation: Equatable {

    public static func == (lhs: QueryPredicateOperation, rhs: QueryPredicateOperation) -> Bool {
        switch (lhs, rhs) {
        case (.true, .true):
            return true
        case (.false, .false):
            return true
        case let (.operation(lfield, lop), .operation(rfield, rop)):
            return lfield == rfield && lop == rop
        case let (.and(lpredicates), .and(rpredicates)):
            return lpredicates == rpredicates
        case let (.or(lpredicates), .or(rpredicates)):
            return lpredicates == rpredicates
        case let (.not(lpredicate), .not(rpredicate)):
            return lpredicate == rpredicate
        default:
            return false
        }
    }

}

extension Array where Element == QueryPredicateOperation {
    public func fold(
        _ nextPartialResult: (QueryPredicateOperation, QueryPredicateOperation) -> QueryPredicateOperation
    ) -> QueryPredicateOperation? {
        if self.isEmpty { return nil }
        if self.count == 1 { return self.first }

        return self.dropFirst().reduce(self.first!, nextPartialResult)
    }
}
