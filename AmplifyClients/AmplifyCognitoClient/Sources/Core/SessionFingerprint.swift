//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The single place that decides a session's identity: which record it reads (the namespace) and
/// which settings every handle on it must agree on (the fingerprint).
struct SessionIdentity: Sendable {
    let namespace: SessionStorageNamespace
    let fingerprint: SessionFingerprint

    init(configuration: AuthClientConfiguration, options: AmplifyCognitoClient.Options) {
        self.init(
            configuration: configuration,
            accessGroup: options.accessGroup,
            customizesUserPoolClient: options.configureUserPoolClient != nil
        )
    }

    init(configuration: AuthClientConfiguration, accessGroup: String?, customizesUserPoolClient: Bool) {
        self.namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        self.fingerprint = SessionFingerprint(
            configuration: configuration,
            customizesUserPoolClient: customizesUserPoolClient
        )
    }
}

/// Everything beyond the namespace that must agree for two handles to share one session.
///
/// What the engine is configured with (`EngineConfigurationInput`), not the whole public configuration.
/// It holds both pools, the app client ID and secret, the regions, the hosted UI and the Authenticator
/// settings the engine carries. Settings the engine never receives do not take part. These are the redirect
/// URIs past the first, identity providers, response type, MFA, guest access, and the standard attributes
/// the engine drops. So a handle read from `amplify_outputs` and one built from pool IDs alone join when
/// the engine would treat them alike. Scope order is not compared either, because OAuth scopes are a set.
/// Any field the engine input gains joins the comparison automatically. Compared for equality only, never
/// hashed, digested or logged, so the app client secret is never transformed.
///
/// `customizesUserPoolClient` records whether the handle passed an escape-hatch closure. A joining
/// handle's closure is never applied (the session's SDK client is the first handle's), so one handle
/// customizing and another not is a contradiction and throws. Two closures cannot be compared, so two
/// customizing handles join and the first one's closure wins.
struct SessionFingerprint: Equatable, Sendable {
    let engineInput: EngineConfigurationInput
    let customizesUserPoolClient: Bool

    init(configuration: AuthClientConfiguration, customizesUserPoolClient: Bool) {
        self.engineInput = Self.sortingScopes(configuration.engineInput)
        self.customizesUserPoolClient = customizesUserPoolClient
    }

    private static func sortingScopes(_ input: EngineConfigurationInput) -> EngineConfigurationInput {
        func sorted(_ userPool: EngineUserPoolSettings) -> EngineUserPoolSettings {
            var userPool = userPool
            userPool.hostedUIConfig?.oauth.scopes.sort()
            return userPool
        }
        switch input {
        case .userPools(let userPool):
            return .userPools(sorted(userPool))
        case .identityPools:
            return input
        case .userPoolsAndIdentityPools(let userPool, let identityPool):
            return .userPoolsAndIdentityPools(sorted(userPool), identityPool)
        }
    }
}

/// The process-wide registry of live sessions. A non-generic holder, because Swift does not allow a
/// static stored property on a generic type. Internal, with no public accessor.
enum SessionCoreRegistry {
    static let shared = SessionCoreDependencies.Registry()
}
