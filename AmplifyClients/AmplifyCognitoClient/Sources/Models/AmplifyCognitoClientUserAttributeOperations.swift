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
public struct AmplifyCognitoClientUpdateUserAttributesOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AmplifyCognitoClientUpdateUserAttributesOptions: Equatable {}

extension AmplifyCognitoClientUpdateUserAttributesOptions: Sendable {}

/// Options for `AmplifyCognitoClient.sendVerificationCode(forUserAttributeKey:options:)`.
///
/// The client's counterpart of Amplify core's `AuthSendUserAttributeVerificationCodeRequest.Options` with
/// the plugin's `AWSSendUserAttributeVerificationCodeOptions` folded in.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientSendVerificationCodeOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AmplifyCognitoClientSendVerificationCodeOptions: Equatable {}

extension AmplifyCognitoClientSendVerificationCodeOptions: Sendable {}

/// The outcome of updating one user attribute.
///
/// Mirrors Amplify core's `AuthUpdateAttributeResult`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientUpdateAttributeResult {

    /// Whether the attribute has been updated.
    public let isUpdated: Bool

    /// What the update needs next.
    public let nextStep: AmplifyCognitoClientUpdateAttributeStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(isUpdated: Bool, nextStep: AmplifyCognitoClientUpdateAttributeStep) {
        self.isUpdated = isUpdated
        self.nextStep = nextStep
    }
}

extension AmplifyCognitoClientUpdateAttributeResult: Equatable {}

extension AmplifyCognitoClientUpdateAttributeResult: Sendable {}

/// The next step of an attribute update.
///
/// Mirrors Amplify core's `AuthUpdateAttributeStep` case for case; `AdditionalInfo` is `[String: String]`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AmplifyCognitoClientUpdateAttributeStep {

    /// Call `confirm(userAttribute:confirmationCode:)` with the code sent to the destination.
    case confirmAttributeWithCode(AmplifyCognitoClientCodeDeliveryDetails, [String: String]?)

    /// The update is complete.
    case done
}

extension AmplifyCognitoClientUpdateAttributeStep: Equatable {}

extension AmplifyCognitoClientUpdateAttributeStep: Sendable {}

/// Options for `AmplifyCognitoClient.fetchUserAttributes(options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthFetchUserAttributesRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientFetchUserAttributesOptions {

    public init() {}
}

extension AmplifyCognitoClientFetchUserAttributesOptions: Equatable {}

extension AmplifyCognitoClientFetchUserAttributesOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirm(userAttribute:confirmationCode:options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthConfirmUserAttributeRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientConfirmUserAttributeOptions {

    public init() {}
}

extension AmplifyCognitoClientConfirmUserAttributeOptions: Equatable {}

extension AmplifyCognitoClientConfirmUserAttributeOptions: Sendable {}
