//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import Foundation
import SmithyIdentity

/// An authorizer that provides credentials for a specific AppSync auth mode.
///
/// Each case encodes its auth mode and holds the provider needed to produce
/// authorization credentials for that mode.
public enum AppSyncAuthorizer: @unchecked Sendable {

    /// API Key authorization.
    /// - Parameter fetchApiKey: Async function that provides the API key.
    case apiKey(_ fetchApiKey: @Sendable () async throws -> String)

    /// Amazon Cognito User Pools authorization.
    /// - Parameter fetchToken: Async function that returns a valid access/ID token.
    case userPools(_ fetchToken: @Sendable () async throws -> String)

    /// OpenID Connect authorization.
    /// - Parameter fetchToken: Async function that returns a valid OIDC token.
    case oidc(_ fetchToken: @Sendable () async throws -> String)

    /// AWS Lambda custom authorization.
    /// - Parameter fetchToken: Async function that returns a valid authorization token.
    case lambda(_ fetchToken: @Sendable () async throws -> String)

    /// IAM (SigV4) authorization.
    /// - Parameter credentialIdentityResolver: Provides IAM credentials for SigV4 signing.
    case iam(_ credentialIdentityResolver: any AWSCredentialIdentityResolver)

    /// The auth mode this authorizer provides.
    public var authMode: AppSyncAuthMode {
        switch self {
        case .apiKey: return .apiKey
        case .userPools: return .userPools
        case .oidc: return .oidc
        case .lambda: return .lambda
        case .iam: return .iam
        }
    }
}

// Convenience factory for static API key
extension AppSyncAuthorizer {
    /// Creates an API Key authorizer with a static key value.
    public static func apiKey(_ apiKey: String) -> AppSyncAuthorizer {
        .apiKey { apiKey }
    }
}
