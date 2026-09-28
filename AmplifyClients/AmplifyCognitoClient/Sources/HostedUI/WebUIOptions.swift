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
/// default of `prefersEphemeralSession`. The rest carry every option the plugin's hosted-UI sign-in accepts, so
/// the client is at parity with it:
///
/// | Here | Plugin | Authorize query item |
/// |---|---|---|
/// | `scopes` | `AuthWebUISignInRequest.Options.scopes` | `scope` |
/// | `provider` | the `for authProvider:` overload's argument | `identity_provider` |
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
public struct WebUIOptions {

    /// What to do when another session already has a browser sign-in in flight. `.fail` by default.
    ///
    /// Only one browser sign-in is in flight per process, across every session and every client.
    /// That is a library policy rather than an OS guarantee: a flow needs a foreground-active
    /// presentation anchor, and a device cannot offer two.
    public var whenBrowserBusy: BrowserBusyPolicy

    /// Whether to ask for a private (ephemeral) browser session. `true` by default.
    ///
    /// Without it the browser shares one Cognito session cookie, so signing a second session in
    /// would silently return the first session's user. This is the plugin's `preferPrivateSession`
    /// with the opposite default.
    ///
    /// Best effort: it sets `ASWebAuthenticationSession.prefersEphemeralWebBrowserSession`, which
    /// Safari always honours and another default browser might not.
    public var prefersEphemeralSession: Bool

    /// The OAuth scopes to request. `nil`, the default, requests the scopes in the configuration.
    ///
    /// Sent sorted and space-separated, as the plugin sends them.
    public var scopes: [String]?

    /// A federated provider to go straight to, skipping Cognito's provider picker.
    ///
    /// Ignored when `idpIdentifier` is set, which is the plugin's precedence.
    public var provider: AuthClientProvider?

    /// Identifies one of several instances of the same kind of provider, for example one of two
    /// SAML providers. When set, the hosted UI asks only for an email address instead of listing
    /// the providers. Takes precedence over `provider`.
    public var idpIdentifier: String?

    /// A random value to include in the request. Cognito copies it into the ID token's `nonce`
    /// claim, so the app can compare the two to guard against replay.
    public var nonce: String?

    /// The language to show the user-interactive pages in. See
    /// [managed login localization](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-managed-login.html#managed-login-localization).
    public var language: String?

    /// A username, email address or phone number to pre-fill the sign-in page with.
    public var loginHint: String?

    /// OIDC `prompt` values, controlling what happens to an existing browser session. `[.login]`
    /// forces re-authentication even if a Cognito cookie survived.
    ///
    /// Sent space-separated, in the order given.
    public var prompt: [Prompt]?

    /// A resource to bind to the access token's `aud` claim. Must begin with `https://`,
    /// `http://localhost`, or a custom URL scheme such as `myapp://`.
    public var resource: String?

    /// Which user the sign-in must return. `.none` by default: any user may come back, as with the
    /// plugin.
    ///
    /// Whatever it is, the client always checks that the tokens that come back belong to this flow and
    /// this app (the ID token's `token_use`, `aud`, `iss`, and the nonce, which it mints when `nonce` is
    /// `nil`). When the check fails nobody is signed in and nothing is stored.
    public var identityExpectation: IdentityExpectation

    public init(
        whenBrowserBusy: BrowserBusyPolicy = .fail,
        prefersEphemeralSession: Bool = true,
        scopes: [String]? = nil,
        provider: AuthClientProvider? = nil,
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
        self.provider = provider
        self.idpIdentifier = idpIdentifier
        self.nonce = nonce
        self.language = language
        self.loginHint = loginHint
        self.prompt = prompt
        self.resource = resource
    }
}

extension WebUIOptions: Sendable {}

extension WebUIOptions: Equatable {}

@_spi(AmplifyExperimental)
public extension WebUIOptions {

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

        /// Throw `AuthClientError.browserBusy` straight away, naming the session that holds the
        /// browser. The default: a second browser that appears unprompted once the first sign-in
        /// finishes reads as a bug, so the app is told and can say something useful.
        public static let fail = BrowserBusyPolicy(.fail)

        /// The longest a caller can wait: one hour. `wait(timeout:)` clamps anything longer, so an
        /// app's wait is always bounded, as the design requires: an unbounded wait turns a stuck
        /// sign-in into a hang with no error.
        public static let maximumWaitTimeout: TimeInterval = 3_600

        /// Wait for the sign-ins ahead of this one to finish, first come first served, then proceed.
        /// Throws `AuthClientError.browserBusy` if `timeout` seconds pass first, and
        /// `CancellationError` if the calling task is cancelled while waiting. Neither takes the
        /// browser.
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
    /// `AuthClientError.unexpectedIdentity`, with nobody signed in. Asking again with `prompt: [.login]`
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
        case distinctFromOtherSessions
    }
}

extension WebUIOptions.BrowserBusyPolicy: Sendable {}

extension WebUIOptions.BrowserBusyPolicy: Equatable {}

extension WebUIOptions.Prompt: Sendable {}

extension WebUIOptions.Prompt: CaseIterable {}

extension WebUIOptions.IdentityExpectation: Sendable {}

extension WebUIOptions.IdentityExpectation: Equatable {}

extension WebUIOptions {

    /// The authorize-request query items these options contribute: `scope`, then the optional items
    /// in the relative order the plugin's `HostedUIRequestHelper.createSignInURL` appends them.
    ///
    /// The rest of the request (`response_type`, `client_id`, `state`, `redirect_uri`, the PKCE
    /// challenge, `userContextData`) comes from the configuration and the flow, not from options.
    /// The plugin places `code_challenge` and `userContextData` between `scope` and the optional
    /// items, so these are not a contiguous run of the plugin's URL; order has no meaning on the
    /// wire, so a URL test should compare items as a set.
    ///
    /// One deliberate difference: an empty `prompt` array sends no `prompt` item, where the plugin
    /// sends an empty one.
    func authorizeQueryItems(configuredScopes: [String]) -> [URLQueryItem] {
        let scope = (scopes ?? configuredScopes).sorted().joined(separator: " ")
        var items = [URLQueryItem(name: "scope", value: scope)]
        if let idpIdentifier {
            items.append(.init(name: "idp_identifier", value: idpIdentifier))
        } else if let provider {
            items.append(.init(name: "identity_provider", value: provider.userPoolProviderName))
        }
        if let nonce {
            items.append(.init(name: "nonce", value: nonce))
        }
        if let language {
            items.append(.init(name: "lang", value: language))
        }
        if let loginHint {
            items.append(.init(name: "login_hint", value: loginHint))
        }
        if let prompt, !prompt.isEmpty {
            items.append(.init(name: "prompt", value: prompt.map(\.rawValue).joined(separator: " ")))
        }
        if let resource {
            items.append(.init(name: "resource", value: resource))
        }
        return items
    }
}
#endif
