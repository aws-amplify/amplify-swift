//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Foundation

/// Options for a hosted-UI (browser) sign-in.
///
/// Three things are new with this client: `whenBrowserBusy`, `identityExpectation`, and the ephemeral
/// default of `prefersEphemeralSession`. The rest carry every option the plugin's hosted-UI sign-in accepts, and
/// two of them send something other than the plugin does: an empty `prompt` list sends no `prompt` item, where
/// the plugin sends an empty one, and a `nil` or empty `nonce` sends one the client mints, for the token checks
/// `identityExpectation` describes, where the plugin sends an empty `nonce` as it is:
///
/// | Here | Plugin | Authorize query item |
/// |---|---|---|
/// | `scopes` | `AuthWebUISignInRequest.Options.scopes` | `scope` |
/// | the `for:` overload's provider | the `for authProvider:` overload's argument | `identity_provider` |
/// | `idpIdentifier` | `AWSAuthWebUISignInOptions.idpIdentifier` | `idp_identifier` |
/// | `prefersEphemeralSession` | `AWSAuthWebUISignInOptions.preferPrivateSession` | none: sets `prefersEphemeralWebBrowserSession` |
/// | `nonce` | `AWSAuthWebUISignInOptions.nonce` | `nonce` |
/// | `language` | `AWSAuthWebUISignInOptions.language` | `lang` |
/// | `loginHint` | `AWSAuthWebUISignInOptions.loginHint` | `login_hint` |
/// | `prompt` | `AWSAuthWebUISignInOptions.prompt` | `prompt` |
/// | `resource` | `AWSAuthWebUISignInOptions.resource` | `resource` |
/// | `whenBrowserBusy` | none: the plugin queues silently | none |
/// | `identityExpectation` | none: the plugin checks nothing | none: checked against the returned ID token |
///
/// Available on iOS, macOS and visionOS only, the platforms the plugin's hosted UI supports:
/// tvOS and watchOS have no `ASWebAuthenticationSession`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientWebUIOptions {

    /// What to do when another session already holds the system sheet. `.fail` by default.
    ///
    /// The client's sessions show one system sheet at a time per process, across every session of
    /// every `AmplifyCognitoClient`: a hosted-UI sign-in or sign-out page, or a passkey sheet. That is a
    /// library policy rather than an OS guarantee: a flow needs a foreground-active presentation
    /// anchor, and a device cannot offer two. The Auth plugin's own hosted UI and passkey sheets do not
    /// take part, so one of them can be up beside a client's sheet.
    public let whenBrowserBusy: BrowserBusyPolicy

    /// Whether to ask for a private (ephemeral) browser session. `true` by default.
    ///
    /// Without it the browser shares one Cognito session cookie, so signing a second session in
    /// would silently return the first session's user. This is the plugin's `preferPrivateSession`
    /// with the opposite default.
    ///
    /// Best effort: it sets `ASWebAuthenticationSession.prefersEphemeralWebBrowserSession`, which
    /// Safari always honours and another default browser might not.
    public let prefersEphemeralSession: Bool

    /// The OAuth scopes to request. `nil`, the default, requests the scopes in the configuration.
    ///
    /// Sent sorted and space-separated, as the plugin sends them.
    public let scopes: [String]?

    /// A federated provider to go straight to, skipping Cognito's provider picker. Not public: set only by
    /// `signInWithWebUI(for:presentationAnchor:options:)` (`with(provider:)`), as the plugin keeps its provider on
    /// the request.
    ///
    /// Ignored when `idpIdentifier` is set, which is the plugin's precedence.
    let provider: AmplifyCognitoClientProvider?

    /// Identifies one of several instances of the same kind of provider, for example one of two
    /// SAML providers. When set, the hosted UI asks only for an email address instead of listing
    /// the providers. Takes precedence over the provider given to
    /// `signInWithWebUI(for:presentationAnchor:options:)`.
    public let idpIdentifier: String?

    /// A random value to include in the request. Cognito copies it into the ID token's `nonce`
    /// claim, so the app can compare the two to guard against replay.
    ///
    /// `nil` or an empty string sends one the client mints; the plugin sends an empty one as it is.
    public let nonce: String?

    /// The language to show the user-interactive pages in. See
    /// [managed login localization](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-managed-login.html#managed-login-localization).
    public let language: String?

    /// A username, email address or phone number to pre-fill the sign-in page with.
    public let loginHint: String?

    /// OIDC `prompt` values, controlling what happens to an existing browser session. `[.login]`
    /// forces re-authentication even if a Cognito cookie survived.
    ///
    /// Sent space-separated, in the order given. An empty list sends no `prompt` item, as `nil` does; the plugin
    /// sends an empty one.
    public let prompt: [Prompt]?

    /// A resource to bind to the access token's `aud` claim. Must begin with `https://`,
    /// `http://localhost`, or a custom URL scheme such as `myapp://`.
    public let resource: String?

    /// Which user the sign-in must return. `.none` by default: any user may come back, as with the
    /// plugin.
    ///
    /// Whatever it is, the client always checks that the tokens that come back belong to this flow and
    /// this app (the ID token's `token_use`, `aud`, `iss`, and the nonce, which it mints when `nonce` is
    /// `nil` or empty). When the check fails nobody is signed in and nothing is stored.
    public let identityExpectation: IdentityExpectation

    /// Each parameter defaults to its field's default. The provider is not a parameter: pass it to
    /// `signInWithWebUI(for:presentationAnchor:options:)`.
    public init(
        whenBrowserBusy: BrowserBusyPolicy = .fail,
        prefersEphemeralSession: Bool = true,
        scopes: [String]? = nil,
        idpIdentifier: String? = nil,
        nonce: String? = nil,
        language: String? = nil,
        loginHint: String? = nil,
        prompt: [Prompt]? = nil,
        resource: String? = nil,
        identityExpectation: IdentityExpectation = .none
    ) {
        self.identityExpectation = identityExpectation
        self.whenBrowserBusy = whenBrowserBusy
        self.prefersEphemeralSession = prefersEphemeralSession
        self.scopes = scopes
        self.provider = nil
        self.idpIdentifier = idpIdentifier
        self.nonce = nonce
        self.language = language
        self.loginHint = loginHint
        self.prompt = prompt
        self.resource = resource
    }

    /// These options with `provider`: what `signInWithWebUI(for:presentationAnchor:options:)` signs in with. The
    /// fields are `let`, so the overload builds a new value.
    func with(provider: AmplifyCognitoClientProvider) -> AmplifyCognitoClientWebUIOptions {
        AmplifyCognitoClientWebUIOptions(copying: self, provider: provider)
    }

    private init(copying options: AmplifyCognitoClientWebUIOptions, provider: AmplifyCognitoClientProvider) {
        self.identityExpectation = options.identityExpectation
        self.whenBrowserBusy = options.whenBrowserBusy
        self.prefersEphemeralSession = options.prefersEphemeralSession
        self.scopes = options.scopes
        self.provider = provider
        self.idpIdentifier = options.idpIdentifier
        self.nonce = options.nonce
        self.language = options.language
        self.loginHint = options.loginHint
        self.prompt = options.prompt
        self.resource = options.resource
    }
}

extension AmplifyCognitoClientWebUIOptions: Sendable {}

extension AmplifyCognitoClientWebUIOptions: Equatable {}

@_spi(AmplifyExperimental)
public extension AmplifyCognitoClientWebUIOptions {

    /// What a hosted-UI sign-in does when another session's browser sign-in is already in flight.
    ///
    /// A struct with two constructors rather than an enum, so a timeout is checked when the policy is
    /// made: a policy never holds NaN, and every policy equals itself.
    struct BrowserBusyPolicy {

        private enum Kind: Equatable {
            case fail
            case wait(nanoseconds: UInt64)
        }

        private let kind: Kind

        private init(_ kind: Kind) {
            self.kind = kind
        }

        /// Throw `AmplifyCognitoClientError.browserBusy` straight away, naming the session that holds the
        /// browser. The default: a second browser that appears unprompted once the first sign-in
        /// finishes reads as a bug, so the app is told and can say something useful.
        public static let fail = BrowserBusyPolicy(.fail)

        /// The longest a caller can wait: one hour. `wait(timeout:)` clamps anything longer, so an
        /// app's wait is always bounded, as the design requires: an unbounded wait turns a stuck
        /// sign-in into a hang with no error.
        public static let maximumWaitTimeout: TimeInterval = 3_600

        /// Wait for the sign-ins ahead of this one to finish, first come first served, then proceed.
        /// Throws `AmplifyCognitoClientError.browserBusy` if `timeout` seconds pass first, and
        /// `CancellationError` if the calling task is cancelled while waiting. Neither takes the
        /// browser. A hosted-UI sign-in that waits holds its session's place for sign-ins meanwhile: a
        /// password sign-in's challenge is still reported, but `confirmSignIn` queues behind it, and
        /// fails with `invalidState` if the hosted UI then takes the sheet; `cancelWebUISignIn()`, or
        /// cancelling the call, ends the wait and keeps the challenge.
        ///
        /// Seconds rather than `Duration`, which needs iOS 16. A timeout that is zero, negative, NaN
        /// or shorter than a nanosecond gives `.fail`. One longer than `maximumWaitTimeout`,
        /// including `.infinity`, is clamped to it.
        public static func wait(timeout: TimeInterval) -> BrowserBusyPolicy {
            guard timeout > 0 else {
                // Also catches NaN, for which every comparison is false.
                return .fail
            }
            let nanoseconds = UInt64(min(timeout, maximumWaitTimeout) * 1_000_000_000)
            guard nanoseconds > 0 else {
                return .fail
            }
            return BrowserBusyPolicy(.wait(nanoseconds: nanoseconds))
        }

        /// Wait with no bound at all. Not for apps: it exists so the plugin can keep its silent
        /// queue, which it has always had, if it is re-based on this client.
        package static let waitWithoutBound = BrowserBusyPolicy(.wait(nanoseconds: .max))

        /// How long a waiter may queue, in nanoseconds, for `Task.sleep(nanoseconds:)`. `nil` for
        /// `.fail`, and `UInt64.max` for `waitWithoutBound`, which starts no timer.
        var timeoutNanoseconds: UInt64? {
            switch kind {
            case .fail:
                return nil
            case .wait(let nanoseconds):
                return nanoseconds
            }
        }
    }

    /// An OIDC `prompt` value. The same cases and raw values as the plugin's
    /// `AWSAuthWebUISignInOptions.Prompt`.
    ///
    /// May gain cases in a minor release: include `@unknown default` when you switch over it.
    enum Prompt: String {

        /// Continue silently for a user who already has a valid session, and return
        /// `login_required` for one who does not.
        case none

        /// Re-authenticate even if the user has an existing session. Cognito issues a new session
        /// cookie, and IdPs that accept the parameter are asked to re-authenticate too.
        case login

        /// Ask the IdP to let the user choose an account. No effect on local sign-in.
        case selectAccount = "select_account"

        /// Ask the IdP to request consent before redirecting back. No effect on local sign-in.
        case consent
    }

    /// Which user a hosted-UI sign-in must return.
    ///
    /// A browser can complete a sign-in without the user typing anything, from a cookie an earlier
    /// sign-in left, and then it returns *that* account. With several sessions, that is one session's
    /// user silently signing in to another. An expectation turns it into an error:
    /// `AmplifyCognitoClientError.unexpectedIdentity`, with nobody signed in. Asking again with `prompt: [.login]`
    /// makes the browser ask for credentials.
    ///
    /// May gain cases in a minor release: include `@unknown default` when you switch over it.
    enum IdentityExpectation {

        /// No expectation: any user may come back. The default, since the same user may be signed in
        /// to two sessions.
        case none

        /// The user that comes back must be this one: a user ID (`sub`) or a username, compared exactly.
        /// An alias (an email address or phone number) never matches.
        case matches(String)

        /// The user that comes back must not be signed in to another session of this client's
        /// configuration (a saved, signed-in session): the "add another account" intent.
        ///
        /// The other sessions are read before the browser is shown, and a session that cannot be read then fails
        /// the sign-in with `storageUnavailable`. They are read again once the browser returns, since another
        /// session may have signed the user in while this one waited; if that second read fails, a warning is
        /// logged under `AmplifyCognitoClient.HostedUI` and the sign-in completes on the first check.
        case distinctFromOtherSessions
    }
}

extension AmplifyCognitoClientWebUIOptions.BrowserBusyPolicy: Sendable {}

extension AmplifyCognitoClientWebUIOptions.BrowserBusyPolicy: Equatable {}

extension AmplifyCognitoClientWebUIOptions.Prompt: Sendable {}

extension AmplifyCognitoClientWebUIOptions.Prompt: CaseIterable {}

extension AmplifyCognitoClientWebUIOptions.IdentityExpectation: Sendable {}

extension AmplifyCognitoClientWebUIOptions.IdentityExpectation: Equatable {}

#endif
