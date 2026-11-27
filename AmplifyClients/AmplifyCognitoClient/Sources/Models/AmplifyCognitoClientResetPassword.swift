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
public struct AmplifyCognitoClientResetPasswordOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AmplifyCognitoClientResetPasswordOptions: Equatable {}

extension AmplifyCognitoClientResetPasswordOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirmResetPassword(for:with:confirmationCode:options:)`.
///
/// The client's counterpart of Amplify core's `AuthConfirmResetPasswordRequest.Options` with the plugin's
/// `AWSAuthConfirmResetPasswordOptions` folded in.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientConfirmResetPasswordOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AmplifyCognitoClientConfirmResetPasswordOptions: Equatable {}

extension AmplifyCognitoClientConfirmResetPasswordOptions: Sendable {}

/// The outcome of `resetPassword`.
///
/// Mirrors Amplify core's `AuthResetPasswordResult`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientResetPasswordResult {

    /// Whether the password has been reset.
    public let isPasswordReset: Bool

    /// What the reset needs next.
    public let nextStep: AmplifyCognitoClientResetPasswordStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(isPasswordReset: Bool, nextStep: AmplifyCognitoClientResetPasswordStep) {
        self.isPasswordReset = isPasswordReset
        self.nextStep = nextStep
    }
}

extension AmplifyCognitoClientResetPasswordResult: Equatable {}

extension AmplifyCognitoClientResetPasswordResult: Sendable {}

/// The next step of a password reset.
///
/// Mirrors Amplify core's `AuthResetPasswordStep` case for case; `AdditionalInfo` is `[String: String]`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AmplifyCognitoClientResetPasswordStep {

    /// Call `confirmResetPassword(for:with:confirmationCode:options:)` with the code sent to the
    /// destination.
    case confirmResetPasswordWithCode(AmplifyCognitoClientCodeDeliveryDetails, [String: String]?)

    /// The reset is complete.
    case done
}

extension AmplifyCognitoClientResetPasswordStep: Equatable {}

extension AmplifyCognitoClientResetPasswordStep: Sendable {}

/// Options for `AmplifyCognitoClient.update(oldPassword:to:options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthChangePasswordRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientChangePasswordOptions {

    /// No options yet.
    public init() {}
}

extension AmplifyCognitoClientChangePasswordOptions: Equatable {}

extension AmplifyCognitoClientChangePasswordOptions: Sendable {}
