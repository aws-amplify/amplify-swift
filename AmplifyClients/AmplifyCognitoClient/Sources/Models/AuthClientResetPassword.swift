//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Options for `AmplifyCognitoClient.resetPassword(for:options:)`.
///
/// The client's counterpart of Amplify core's `AuthResetPasswordRequest.Options` with the plugin's
/// `AWSAuthResetPasswordOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientResetPasswordOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientResetPasswordOptions: Equatable {}

extension AuthClientResetPasswordOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirmResetPassword(for:with:confirmationCode:options:)`.
///
/// The client's counterpart of Amplify core's `AuthConfirmResetPasswordRequest.Options` with the plugin's
/// `AWSAuthConfirmResetPasswordOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientConfirmResetPasswordOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientConfirmResetPasswordOptions: Equatable {}

extension AuthClientConfirmResetPasswordOptions: Sendable {}

/// The outcome of `resetPassword`.
///
/// Mirrors Amplify core's `AuthResetPasswordResult`.
@_spi(AmplifyExperimental)
public struct AuthClientResetPasswordResult {

    /// Whether the password has been reset.
    public let isPasswordReset: Bool

    /// What the reset needs next.
    public let nextStep: AuthClientResetPasswordStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(isPasswordReset: Bool, nextStep: AuthClientResetPasswordStep) {
        self.isPasswordReset = isPasswordReset
        self.nextStep = nextStep
    }
}

extension AuthClientResetPasswordResult: Equatable {}

extension AuthClientResetPasswordResult: Sendable {}

/// The next step of a password reset.
///
/// Mirrors Amplify core's `AuthResetPasswordStep` case for case; `AdditionalInfo` is `[String: String]`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientResetPasswordStep {

    /// Call `confirmResetPassword(for:with:confirmationCode:options:)` with the code sent to the
    /// destination.
    case confirmResetPasswordWithCode(AuthClientCodeDeliveryDetails, [String: String]?)

    /// The reset is complete.
    case done
}

extension AuthClientResetPasswordStep: Equatable {}

extension AuthClientResetPasswordStep: Sendable {}

/// Options for `AmplifyCognitoClient.update(oldPassword:to:options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthChangePasswordRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AuthClientChangePasswordOptions {

    public init() {}
}

extension AuthClientChangePasswordOptions: Equatable {}

extension AuthClientChangePasswordOptions: Sendable {}
