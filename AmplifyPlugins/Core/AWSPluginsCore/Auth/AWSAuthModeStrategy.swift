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
    func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypesIterator
}

// MARK: - AWSDefaultAuthModeStrategy

public struct AWSDefaultAuthModeStrategy: AuthModeStrategy {
    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypesIterator {
        return [].makeIterator()
    }
}

// MARK: - AWSMultiAuthModeStrategy

/// Multi-auth strategy implementation based on schema metadata
public struct AWSMultiAuthModeStrategy: AuthModeStrategy {
    private typealias AuthStrategyPriority = Int
    private static let authStrategyPriority: [AuthStrategy: AuthStrategyPriority] = [
        .owner : 0,
        .groups: 1,
        .private: 2,
        .public: 3
    ]

    private static let authStrategyTypesMap: [AuthStrategy: AWSAuthorizationType] = [
        .owner : .amazonCognitoUserPools,
        .groups : .amazonCognitoUserPools,
        .private : .amazonCognitoUserPools,
        .public : .apiKey
    ]
    
    private static let comparator = { (rule1: AuthRule, rule2: AuthRule) -> Bool in
        Self.authStrategyPriority[rule1.allow]! < Self.authStrategyPriority[rule2.allow]!
    }

    public init() {}

    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypesIterator {
        let applicableAuthRules = schema.authRules
            .filter(modelOperation: operation)
            .sorted(by: AWSMultiAuthModeStrategy.comparator)
            .map { Self.authStrategyTypesMap[$0.allow]! }
        
        return applicableAuthRules.makeIterator()
        
    }
}
