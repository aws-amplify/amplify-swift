//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Represents different auth strategies supported by a client
/// interfacing with an AppSync backend
public enum AuthModeStrategyType {
    /// Default authorization type read from API configuration
    case `default`

    /// Uses schema metadata to create a prioritized list of potential authorization types
    /// that could be used for a request. The client iterates through that list until one of the
    /// avaialable types succecceds or all of them fail.
    case multiAuth

    /// Custom provided authorization strategy.
    case custom(AuthModeStrategy)
}

public typealias AWSAuthorizationTypesIterator = IndexingIterator<[AWSAuthorizationType]>

/// Represents an authorization strategy used by DataStore
public protocol AuthModeStrategy {
    init()
    func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypesIterator
}

// MARK: - AWSDefaultAuthModeStrategy

public struct AWSDefaultAuthModeStrategy: AuthModeStrategy {
    
    public init() {}
    
    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypesIterator {
        return [].makeIterator()
    }
}

// MARK: - AWSMultiAuthModeStrategy

/// Multi-auth strategy implementation based on schema metadata
public struct AWSMultiAuthModeStrategy: AuthModeStrategy {
    private typealias AuthStrategyPriority = Int
    
    public init() {}

    private static func authTypeFor(authStrategy: AuthStrategy) -> AWSAuthorizationType {
        var authType: AWSAuthorizationType
        switch authStrategy {
        case .owner:
            authType = .amazonCognitoUserPools
        case .groups:
            authType = .amazonCognitoUserPools
        case .private:
            authType = .amazonCognitoUserPools
        case .public:
            authType = .apiKey
        }
        return authType
    }

    /// Given an auth rule strategy returns its corresponding priority
    /// - Parameter authStrategy: auth rule strategy
    /// - Returns: priority
    private static func priorityOf(authStrategy: AuthStrategy) -> AuthStrategyPriority {
        switch authStrategy {
        case .owner:
            return 0
        case .groups:
            return 1
        case .private:
            return 2
        case .public:
            return 3
        }
    }

    private static let comparator = { (rule1: AuthRule, rule2: AuthRule) -> Bool in
        priorityOf(authStrategy: rule1.allow) < priorityOf(authStrategy: rule2.allow)
    }

    public func authTypesFor(schema: ModelSchema,
                             operation: ModelOperation) -> AWSAuthorizationTypesIterator {
        let applicableAuthRules = schema.authRules
            .filter(modelOperation: operation)
            .sorted(by: AWSMultiAuthModeStrategy.comparator)
            .map { AWSMultiAuthModeStrategy.authTypeFor(authStrategy: $0.allow) }

        return applicableAuthRules.makeIterator()

    }
}
