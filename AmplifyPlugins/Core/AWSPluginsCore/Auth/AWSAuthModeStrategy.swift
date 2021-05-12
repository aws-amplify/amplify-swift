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

public typealias AuthorizationTypes = IndexingIterator<[AWSAuthorizationType]>

public protocol AuthModeStrategy {
    func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AuthorizationTypes
}

public struct AWSDefaultAuthModeStrategy: AuthModeStrategy {
    public init() {
    }

    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AuthorizationTypes {
        [].makeIterator()
    }
}

/// Multi-auth strategy implementation based on schema metadata
public struct AWSMultiAuthModeStrategy: AuthModeStrategy {
    public init() {}
    public func authTypesFor(schema: ModelSchema, operation: ModelOperation) -> AuthorizationTypes {
        [].makeIterator()
    }
}
