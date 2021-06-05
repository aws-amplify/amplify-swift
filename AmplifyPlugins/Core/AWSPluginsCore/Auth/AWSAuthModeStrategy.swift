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

public protocol AuthorizationTypeProvider {
    associatedtype AuthorizationType
    
    init(withValues: [AuthorizationType])
    
    var count: Int { get }
    
    mutating func next() -> AuthorizationType?
}

public struct AWSAuthorizationTypeProvider: AuthorizationTypeProvider {
    public typealias AuthorizationType = AWSAuthorizationType
    
    private var values: IndexingIterator<[AWSAuthorizationType]>
    private var _count: Int
    
    public init(withValues values: [AWSAuthorizationType]) {
        self.values = values.makeIterator()
        self._count = values.count
    }
    
    public var count: Int {
        self._count
    }
    
    public mutating func next() -> AWSAuthorizationType? {
        self.values.next()
    }
    
    
}

/// Represents an authorization strategy used by DataStore
public protocol AuthModeStrategy {
    init()
    func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypeProvider
}

// MARK: - AWSDefaultAuthModeStrategy

public struct AWSDefaultAuthModeStrategy: AuthModeStrategy {
    public init() {}
    
    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AWSAuthorizationTypeProvider {
        return AWSAuthorizationTypeProvider(withValues: [])
    }
}

// MARK: - AWSMultiAuthModeStrategy

/// Multi-auth strategy implementation based on schema metadata
public struct AWSMultiAuthModeStrategy: AuthModeStrategy {
    private typealias AuthStrategyPriority = Int
    
    public init() {}

    private static func authTypeFor(authRule: AuthRule) -> AWSAuthorizationType {
        guard let authProvider = authRule.provider,
              let authType = try? authProvider.toAWSAuthorizationType() else {
            return .amazonCognitoUserPools
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
                             operation: ModelOperation) -> AWSAuthorizationTypeProvider {
        let applicableAuthRules = schema.authRules
            .filter(modelOperation: operation)
            .sorted(by: AWSMultiAuthModeStrategy.comparator)
            .map { AWSMultiAuthModeStrategy.authTypeFor(authRule: $0) }

        return AWSAuthorizationTypeProvider(withValues: applicableAuthRules)

    }
}
