//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Which Cognito authentication flow a sign-in uses.
///
/// Mirrors the plugin's `AuthFlowType` case for case, except the deprecated `custom`, which has no
/// client case: use `customWithSRP`, which is what the plugin sends for it. The plugin's `rawValue` (the
/// Cognito flow name) is not mirrored; the engine owns that mapping, and the bridge maps case to case.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientAuthFlowType {

    /// Authentication flow for the Secure Remote Password (SRP) protocol
    case userSRP

    /// Authentication flow which start with SRP and then move to custom auth flow
    case customWithSRP

    /// Authentication flow which starts without SRP and directly moves to custom auth flow
    case customWithoutSRP

    /// Non-SRP authentication flow; user name and password are passed directly.
    /// If a user migration Lambda trigger is set, this flow will invoke the user migration
    /// Lambda if it doesn't find the user name in the user pool.
    case userPassword

    /// Authentication flow used for user discovering enabled first factors for a user.
    /// - `preferredFirstFactor`: the auth factor type the user should begin signing with if available. If the preferred first factor is not available, the flow would fallback to provide available first factors.
    case userAuth(preferredFirstFactor: AuthClientFactorType?)
}

extension AuthClientAuthFlowType: Equatable {}

extension AuthClientAuthFlowType: Sendable {}
