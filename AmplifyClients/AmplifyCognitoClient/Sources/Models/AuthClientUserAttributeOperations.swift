//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Options for `AmplifyCognitoClient.update(userAttribute:options:)` and
/// `update(userAttributes:options:)`.
///
/// The client's counterpart of Amplify core's `AuthUpdateUserAttributeRequest.Options` and
/// `AuthUpdateUserAttributesRequest.Options`, with the plugin's `AWSAuthUpdateUserAttributeOptions` and
/// `AWSAuthUpdateUserAttributesOptions` folded in. The plugin's four types have the same shape, so the
/// client has one.
@_spi(AmplifyExperimental)
public struct AuthClientUpdateUserAttributesOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientUpdateUserAttributesOptions: Equatable {}

extension AuthClientUpdateUserAttributesOptions: Sendable {}

/// Options for `AmplifyCognitoClient.sendVerificationCode(forUserAttributeKey:options:)`.
///
/// The client's counterpart of Amplify core's `AuthSendUserAttributeVerificationCodeRequest.Options` with
/// the plugin's `AWSSendUserAttributeVerificationCodeOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientSendVerificationCodeOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientSendVerificationCodeOptions: Equatable {}

extension AuthClientSendVerificationCodeOptions: Sendable {}

/// The outcome of updating one user attribute.
///
/// Mirrors Amplify core's `AuthUpdateAttributeResult`.
@_spi(AmplifyExperimental)
public struct AuthClientUpdateAttributeResult {

    /// Whether the attribute has been updated.
    public let isUpdated: Bool

    /// What the update needs next.
    public let nextStep: AuthClientUpdateAttributeStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(isUpdated: Bool, nextStep: AuthClientUpdateAttributeStep) {
        self.isUpdated = isUpdated
        self.nextStep = nextStep
    }
}

extension AuthClientUpdateAttributeResult: Equatable {}

extension AuthClientUpdateAttributeResult: Sendable {}

/// The next step of an attribute update.
///
/// Mirrors Amplify core's `AuthUpdateAttributeStep` case for case; `AdditionalInfo` is `[String: String]`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientUpdateAttributeStep {

    /// Call `confirm(userAttribute:confirmationCode:)` with the code sent to the destination.
    case confirmAttributeWithCode(AuthClientCodeDeliveryDetails, [String: String]?)

    /// The update is complete.
    case done
}

extension AuthClientUpdateAttributeStep: Equatable {}

extension AuthClientUpdateAttributeStep: Sendable {}
