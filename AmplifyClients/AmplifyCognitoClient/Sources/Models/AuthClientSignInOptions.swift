//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth

/// Options for `AmplifyCognitoClient.signIn(username:password:options:)`.
///
/// The client's counterpart of Amplify core's `AuthSignInRequest.Options` with the plugin's
/// `AWSAuthSignInOptions` folded in. The plugin's deprecated `validationData` is not mirrored: the plugin
/// merges it into the client metadata anyway, so pass those values in `clientMetadata`.
@_spi(AmplifyExperimental)
public struct AuthClientSignInOptions {

    /// The authentication flow to use for this sign-in. `nil` uses the configuration's, which is
    /// `userSRP` for an `amplify_outputs` configuration, as for the plugin.
    public var authFlowType: AuthClientAuthFlowType?

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public var clientMetadata: [String: String]

    /// `presentationAnchorForWebAuthn`'s storage, on every platform: empty where there is no passkey sheet.
    var webAuthnAnchor = WeakPresentationAnchor()

    public init(
        authFlowType: AuthClientAuthFlowType? = nil,
        clientMetadata: [String: String] = [:]
    ) {
        self.authFlowType = authFlowType
        self.clientMetadata = clientMetadata
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The window a passkey sheet attaches to, such as the active scene's key window. Amplify core's
    /// `AuthSignInRequest.Options.presentationAnchorForWebAuthn`. iOS, macOS and visionOS only.
    ///
    /// With `authFlowType: .userAuth(preferredFirstFactor: .webAuthn)` (and usually no password), the passkey
    /// sheet is shown over this window, and the result is `.done`. Without a preference, a
    /// `.continueSignInWithFirstFactorSelection` step may offer `.webAuthn`; answer it with
    /// `confirmSignIn(challengeResponse: "WEB_AUTHN")`, which uses this window unless its own options give
    /// one. Any other factor never shows a sheet.
    ///
    /// The client never picks a window itself: a passkey step with no window fails with
    /// `.validation(field: "presentationAnchorForWebAuthn")`. The window is held weakly: if it has gone when
    /// the ceremony starts, nothing is presented, and the call throws the same error. A failed passkey step
    /// ends the sign-in: call `signIn` again to retry.
    ///
    /// Read and set on the main actor, as a window is; the options themselves stay `Sendable`. Two options are
    /// equal only if they were given the same window, or none. (The window is compared by its identity when it
    /// was set, which a later window can reuse once this one has gone.)
    @MainActor
    public var presentationAnchorForWebAuthn: AuthClientPresentationAnchor? {
        get { webAuthnAnchor.box?.anchor }
        set { webAuthnAnchor.box = newValue.map { EnginePresentationAnchorBox($0) } }
    }

    /// Options with the window a passkey sheet attaches to: see `presentationAnchorForWebAuthn`.
    @MainActor
    public init(
        authFlowType: AuthClientAuthFlowType? = nil,
        clientMetadata: [String: String] = [:],
        presentationAnchorForWebAuthn: AuthClientPresentationAnchor?
    ) {
        self.init(authFlowType: authFlowType, clientMetadata: clientMetadata)
        self.presentationAnchorForWebAuthn = presentationAnchorForWebAuthn
    }
    #endif
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

    /// `presentationAnchorForWebAuthn`'s storage, on every platform: empty where there is no passkey sheet.
    var webAuthnAnchor = WeakPresentationAnchor()

    public init(
        userAttributes: [AuthClientUserAttribute] = [],
        clientMetadata: [String: String] = [:],
        friendlyDeviceName: String? = nil
    ) {
        self.userAttributes = userAttributes
        self.clientMetadata = clientMetadata
        self.friendlyDeviceName = friendlyDeviceName
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The window a `"WEB_AUTHN"` answer's passkey sheet attaches to, in place of the one given to `signIn`
    /// (`AuthClientSignInOptions.presentationAnchorForWebAuthn`). Amplify core's
    /// `AuthConfirmSignInRequest.Options.presentationAnchorForWebAuthn`. iOS, macOS and visionOS only.
    ///
    /// `nil`, the default, uses the sign-in's window, and so does a window that has gone by the time of the
    /// call, which reads as `nil` here. With neither window, a `"WEB_AUTHN"` answer is refused with
    /// `.validation(field: "presentationAnchorForWebAuthn")` before anything is sent, and the selection stays
    /// pending. Held weakly, read and set on the main actor, and compared by identity, as the sign-in's is.
    @MainActor
    public var presentationAnchorForWebAuthn: AuthClientPresentationAnchor? {
        get { webAuthnAnchor.box?.anchor }
        set { webAuthnAnchor.box = newValue.map { EnginePresentationAnchorBox($0) } }
    }

    /// Options with the window a `"WEB_AUTHN"` answer's passkey sheet attaches to: see
    /// `presentationAnchorForWebAuthn`.
    @MainActor
    public init(
        userAttributes: [AuthClientUserAttribute] = [],
        clientMetadata: [String: String] = [:],
        friendlyDeviceName: String? = nil,
        presentationAnchorForWebAuthn: AuthClientPresentationAnchor?
    ) {
        self.init(
            userAttributes: userAttributes,
            clientMetadata: clientMetadata,
            friendlyDeviceName: friendlyDeviceName
        )
        self.presentationAnchorForWebAuthn = presentationAnchorForWebAuthn
    }
    #endif
}

extension AuthClientConfirmSignInOptions: Equatable {}

extension AuthClientConfirmSignInOptions: Sendable {}

/// A passkey sheet's window as the sign-in options hold it: in the engine's weak box, so the options stay
/// `Sendable` and never keep a closed window alive, and compared by the window, so they stay `Equatable`.
struct WeakPresentationAnchor: Equatable, Sendable {

    /// The boxed window, or `nil` when the options were given none.
    var box: EnginePresentationAnchorBox?

    /// The same window, or none on both sides. Not the box's own `==`, which is the box's identity: every
    /// set makes a new box.
    static func == (lhs: WeakPresentationAnchor, rhs: WeakPresentationAnchor) -> Bool {
        EnginePresentationAnchorBox.sameWindow(lhs.box, rhs.box)
    }
}

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
