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
public struct AmplifyCognitoClientSignInOptions {

    /// The authentication flow to use for this sign-in. `nil` uses the configuration's, which is
    /// `userSRP` for an `amplify_outputs` configuration, as for the plugin.
    public let authFlowType: AmplifyCognitoClientAuthFlowType?

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    /// `presentationAnchorForWebAuthn`'s storage, on every platform: empty where there is no passkey sheet.
    let webAuthnAnchor: WeakPresentationAnchor

    public init(
        authFlowType: AmplifyCognitoClientAuthFlowType? = nil,
        clientMetadata: [String: String] = [:]
    ) {
        self.authFlowType = authFlowType
        self.clientMetadata = clientMetadata
        self.webAuthnAnchor = WeakPresentationAnchor(box: nil)
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
    /// Read on the main actor, as a window is, and set through the main-actor `init`; the options themselves
    /// stay `Sendable`. Two options are equal only if they were given the same window, or none. (The window is
    /// compared by its identity when it was set, which a later window can reuse once this one has gone.)
    @MainActor
    public var presentationAnchorForWebAuthn: AmplifyCognitoClientPresentationAnchor? {
        webAuthnAnchor.box?.anchor
    }

    /// Options with the window a passkey sheet attaches to: see `presentationAnchorForWebAuthn`.
    @MainActor
    public init(
        authFlowType: AmplifyCognitoClientAuthFlowType? = nil,
        clientMetadata: [String: String] = [:],
        presentationAnchorForWebAuthn: AmplifyCognitoClientPresentationAnchor?
    ) {
        self.authFlowType = authFlowType
        self.clientMetadata = clientMetadata
        self.webAuthnAnchor = WeakPresentationAnchor(box: presentationAnchorForWebAuthn.map { EnginePresentationAnchorBox($0) })
    }
    #endif
}

extension AmplifyCognitoClientSignInOptions: Equatable {}

extension AmplifyCognitoClientSignInOptions: Sendable {}

/// Options for `AmplifyCognitoClient.confirmSignIn(challengeResponse:options:)`.
///
/// The client's counterpart of Amplify core's `AuthConfirmSignInRequest.Options` with the plugin's
/// `AWSAuthConfirmSignInOptions` folded in.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientConfirmSignInOptions {

    /// User attributes to send with the answer, such as the required attributes of a new-password
    /// challenge.
    public let userAttributes: [AmplifyCognitoClientUserAttribute]

    /// Passed to the user pool's Lambda triggers as `ClientMetadata`. The plugin's `metadata`.
    public let clientMetadata: [String: String]

    /// The name to give the device when the answer completes a TOTP setup.
    public let friendlyDeviceName: String?

    /// `presentationAnchorForWebAuthn`'s storage, on every platform: empty where there is no passkey sheet.
    let webAuthnAnchor: WeakPresentationAnchor

    public init(
        userAttributes: [AmplifyCognitoClientUserAttribute] = [],
        clientMetadata: [String: String] = [:],
        friendlyDeviceName: String? = nil
    ) {
        self.userAttributes = userAttributes
        self.clientMetadata = clientMetadata
        self.friendlyDeviceName = friendlyDeviceName
        self.webAuthnAnchor = WeakPresentationAnchor(box: nil)
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// The window a `"WEB_AUTHN"` answer's passkey sheet attaches to, in place of the one given to `signIn`
    /// (`AmplifyCognitoClientSignInOptions.presentationAnchorForWebAuthn`). Amplify core's
    /// `AuthConfirmSignInRequest.Options.presentationAnchorForWebAuthn`. iOS, macOS and visionOS only.
    ///
    /// `nil`, the default, uses the sign-in's window, and so does a window that has gone by the time of the
    /// call, which reads as `nil` here. With no window left (neither was given, or the sign-in's has gone too), a
    /// `"WEB_AUTHN"` answer is refused with `.validation(field: "presentationAnchorForWebAuthn")` before anything
    /// is sent, and the selection stays pending. A window that goes after that check and before the sheet would
    /// appear fails with the same error and ends the sign-in: call `signIn` again. Held weakly, read on the main
    /// actor, set through the main-actor `init`, and compared by identity, as the sign-in's is.
    @MainActor
    public var presentationAnchorForWebAuthn: AmplifyCognitoClientPresentationAnchor? {
        webAuthnAnchor.box?.anchor
    }

    /// Options with the window a `"WEB_AUTHN"` answer's passkey sheet attaches to: see
    /// `presentationAnchorForWebAuthn`.
    @MainActor
    public init(
        userAttributes: [AmplifyCognitoClientUserAttribute] = [],
        clientMetadata: [String: String] = [:],
        friendlyDeviceName: String? = nil,
        presentationAnchorForWebAuthn: AmplifyCognitoClientPresentationAnchor?
    ) {
        self.userAttributes = userAttributes
        self.clientMetadata = clientMetadata
        self.friendlyDeviceName = friendlyDeviceName
        self.webAuthnAnchor = WeakPresentationAnchor(box: presentationAnchorForWebAuthn.map { EnginePresentationAnchorBox($0) })
    }
    #endif
}

extension AmplifyCognitoClientConfirmSignInOptions: Equatable {}

extension AmplifyCognitoClientConfirmSignInOptions: Sendable {}

/// A passkey sheet's window as the sign-in options hold it: in the engine's weak box, so the options stay
/// `Sendable` and never keep a closed window alive, and compared by the window, so they stay `Equatable`.
struct WeakPresentationAnchor: Equatable, Sendable {

    /// The boxed window, or `nil` when the options were given none.
    let box: EnginePresentationAnchorBox?

    /// The same window, or none on both sides. Not the box's own `==`, which is the box's identity: every
    /// `init` makes a new box.
    static func == (lhs: WeakPresentationAnchor, rhs: WeakPresentationAnchor) -> Bool {
        EnginePresentationAnchorBox.sameWindow(lhs.box, rhs.box)
    }
}

/// The outcome of `signIn` or `confirmSignIn`.
///
/// Mirrors Amplify core's `AuthSignInResult`, without its `isSignedIn`: the sign-in is complete when
/// `nextStep` is `.done`, and whether the session is signed in is its state, `currentSessionState()`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientSignInResult {

    /// What the sign-in needs next. `.done` when it is complete.
    public let nextStep: AmplifyCognitoClientSignInStep

    /// Public so an app can build one for a test double; the client builds its own.
    public init(nextStep: AmplifyCognitoClientSignInStep) {
        self.nextStep = nextStep
    }
}

extension AmplifyCognitoClientSignInResult: Equatable {}

extension AmplifyCognitoClientSignInResult: Sendable {}
