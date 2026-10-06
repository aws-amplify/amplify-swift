//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Options for `AmplifyCognitoClient.signIn(username:password:options:)`.
///
/// The client's counterpart of Amplify core's `AuthSignInRequest.Options` with the plugin's
/// `AWSAuthSignInOptions` folded in. The plugin's deprecated `validationData` is not mirrored: the plugin
/// merges it into the client metadata anyway, so pass those values in `clientMetadata`. A WebAuthn
/// presentation anchor arrives with passwordless sign-in.
@_spi(AmplifyExperimental)
public struct AuthClientSignInOptions {

    /// The authentication flow to use for this sign-in. `nil` uses the configuration's, which is
    /// `userSRP` for an `amplify_outputs` configuration, as for the plugin.
    public var authFlowType: AuthClientAuthFlowType?

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    public init(
        authFlowType: AuthClientAuthFlowType? = nil,
        clientMetadata: [String: String] = [:]
    ) {
        self.authFlowType = authFlowType
        self.clientMetadata = clientMetadata
    }
}

extension AuthClientSignInOptions: Equatable {}

extension AuthClientSignInOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirmSignIn(challengeResponse:options:)`.
///
/// The client's counterpart of Amplify core's `AuthConfirmSignInRequest.Options` with the plugin's
/// `AWSAuthConfirmSignInOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientConfirmSignInOptions {

    /// User attributes to send with the answer, such as the required attributes of a new-password
    /// challenge.
    public var userAttributes: [AuthClientUserAttribute]

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    /// The name to give the device when the answer completes a TOTP setup.
    public var friendlyDeviceName: String?

    public init(
        userAttributes: [AuthClientUserAttribute] = [],
        clientMetadata: [String: String] = [:],
        friendlyDeviceName: String? = nil
    ) {
        self.userAttributes = userAttributes
        self.clientMetadata = clientMetadata
        self.friendlyDeviceName = friendlyDeviceName
    }
}

extension AuthClientConfirmSignInOptions: Equatable {}

extension AuthClientConfirmSignInOptions: Sendable {}

/// The outcome of `signIn` or `confirmSignIn`.
///
/// Mirrors Amplify core's `AuthSignInResult`, without its `isSignedIn`: the sign-in is complete when
/// `nextStep` is `.done`, and whether the session is signed in is its state, `currentSessionState()`.
@_spi(AmplifyExperimental)
public struct AuthClientSignInResult {

    /// What the sign-in needs next. `.done` when it is complete.
    public let nextStep: AuthClientSignInStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(nextStep: AuthClientSignInStep) {
        self.nextStep = nextStep
    }
}

extension AuthClientSignInResult: Equatable {}

extension AuthClientSignInResult: Sendable {}
