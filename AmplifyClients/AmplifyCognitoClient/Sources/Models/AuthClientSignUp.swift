//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Options for `AmplifyCognitoClient.signUp(username:password:options:)`.
///
/// The client's counterpart of Amplify core's `AuthSignUpRequest.Options` with the plugin's
/// `AWSAuthSignUpOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientSignUpOptions {

    /// The user attributes to register the user with, such as `email`.
    public var userAttributes: [AuthClientUserAttribute]

    /// Passed to the pre-sign-up Lambda trigger as `ValidationData`. The plugin's `validationData`.
    public var validationData: [String: String]

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    public init(
        userAttributes: [AuthClientUserAttribute] = [],
        validationData: [String: String] = [:],
        clientMetadata: [String: String] = [:]
    ) {
        self.userAttributes = userAttributes
        self.validationData = validationData
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientSignUpOptions: Equatable {}

extension AuthClientSignUpOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirmSignUp(for:confirmationCode:options:)`.
///
/// The client's counterpart of Amplify core's `AuthConfirmSignUpRequest.Options` with the plugin's
/// `AWSAuthConfirmSignUpOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientConfirmSignUpOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    /// Cognito's `ForceAliasCreation`: move an alias (email, phone) that another user already uses to
    /// this user. `nil` leaves Cognito's default.
    public var forceAliasCreation: Bool?

    public init(clientMetadata: [String: String] = [:], forceAliasCreation: Bool? = nil) {
        self.clientMetadata = clientMetadata
        self.forceAliasCreation = forceAliasCreation
    }
}

extension AuthClientConfirmSignUpOptions: Equatable {}

extension AuthClientConfirmSignUpOptions: Sendable {}

/// Options for `AmplifyCognitoClient.resendSignUpCode(for:options:)`.
///
/// The client's counterpart of Amplify core's `AuthResendSignUpCodeRequest.Options` with the plugin's
/// `AWSAuthResendSignUpCodeOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientResendSignUpCodeOptions {

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    public init(clientMetadata: [String: String] = [:]) {
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientResendSignUpCodeOptions: Equatable {}

extension AuthClientResendSignUpCodeOptions: Sendable {}

/// The outcome of `signUp` or `confirmSignUp`.
///
/// Mirrors Amplify core's `AuthSignUpResult`.
@_spi(AmplifyExperimental)
public struct AuthClientSignUpResult {

    /// Whether sign-up is complete: `nextStep` is `.done` or `.completeAutoSignIn`.
    public var isSignUpComplete: Bool {
        switch nextStep {
        case .completeAutoSignIn, .done:
            return true
        case .confirmUser:
            return false
        }
    }

    /// What sign-up needs next.
    public let nextStep: AuthClientSignUpStep

    /// The new user's `sub`, when Cognito returns it.
    public let userId: String?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(_ nextStep: AuthClientSignUpStep, userId: String? = nil) {
        self.nextStep = nextStep
        self.userId = userId
    }
}

extension AuthClientSignUpResult: Equatable {}

extension AuthClientSignUpResult: Sendable {}

/// The next step of a sign-up.
///
/// Mirrors Amplify core's `AuthSignUpStep` case for case, with its typealiases spelled out:
/// `AdditionalInfo` is `[String: String]`, and `UserId` and `Session` are `String`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientSignUpStep {

    /// The user must be confirmed with the code sent to the destination, by
    /// `confirmSignUp(for:confirmationCode:options:)`. Carries the delivery details, any additional
    /// information, and the user's `sub`.
    case confirmUser(
        AuthClientCodeDeliveryDetails? = nil,
        [String: String]? = nil,
        String? = nil
    )

    /// Sign-up is complete, and `autoSignIn()` can sign the user in to this session. Carries Cognito's
    /// session for it.
    case completeAutoSignIn(String)

    /// Sign-up is complete.
    case done
}

extension AuthClientSignUpStep: Equatable {}

extension AuthClientSignUpStep: Sendable {}
