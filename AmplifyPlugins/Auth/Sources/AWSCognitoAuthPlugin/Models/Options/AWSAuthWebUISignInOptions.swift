//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import Foundation

public struct AWSAuthWebUISignInOptions {

    /// Identifier of the underlying authentication provider
    ///
    /// This can be used to identify a provider if there are multiple instance of the same authentication provider.
    /// For example if you have multiple SAML identity providers, you can identify one of them by providing this
    /// `idpIdentifier` value. If this value is set, the webUI will just show a textbox to enter the email address.
    /// On the other hand, if you do not give any value here, the webUI will show the list of identity providers and the
    /// user must select one of them to continue.
    public let idpIdentifier: String?

    /// Starts the webUI signin in a private browser session, if supported by the current browser.
    ///
    /// Note that this value internally sets `prefersEphemeralWebBrowserSession` in ASWebAuthenticationSession.
    /// As per Apple documentation, Whether the request is honored depends on the user’s default web browser.
    /// Safari always honors the request.
    public let preferPrivateSession: Bool

    /// A random value that you can add to the request. The nonce value that you provide is included in the ID token
    /// that Amazon Cognito issues. To guard against replay attacks, your app can inspect the nonce claim in the ID
    /// token and compare it to the one you generated.
    public let nonce: String?

    /// The language that you want to display user-interactive pages in
    /// For more information, see Managed login localization -
    /// https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-managed-login.html#managed-login-localization
    public let language: String?

    /// A username prompt that you want to pass to the authorization server. You can collect a username, email
    /// address or phone number from your user and allow the destination provider to pre-populate the user's
    /// sign-in name.
    public let loginHint: String?

    /// An OIDC parameter that controls authentication behavior for existing sessions.
    public let prompt: [Prompt]?

    /// The identifier of a resource that you want to bind to the access token in the `aud` claim. When you include
    /// this parameter, Amazon Cognito validates that the value is a URL and sets the audience of the resulting
    /// access token to the requested resource. Values for this parameter must begin with "https://", "http://localhost",
    /// or a custom URL scheme like "myapp://".
    public let resource: String?

    public init(
        idpIdentifier: String? = nil,
        preferPrivateSession: Bool = false,
        nonce: String? = nil,
        language: String? = nil,
        loginHint: String? = nil,
        prompt: [Prompt]? = nil,
        resource: String? = nil
    ) {
        self.idpIdentifier = idpIdentifier
        self.preferPrivateSession = preferPrivateSession
        self.nonce = nonce
        self.language = language
        self.loginHint = loginHint
        self.prompt = prompt
        self.resource = resource
    }
}

public extension AWSAuthWebUISignInOptions {

    enum Prompt: String, Codable {
        /// Amazon Cognito silently continues authentication for users who have a valid authenticated session.
        /// With this prompt, users can silently authenticate between different app clients in your user pool.
        /// If the user is not already authenticated, the authorization server returns a login_required error.
        case none

        /// Amazon Cognito requires users to re-authenticate even if they have an existing session. Send this
        /// value when you want to verify the user's identity again. Authenticated users who have an existing
        /// session can return to sign-in without invalidating that session. When a user who has an existing
        /// session signs in again, Amazon Cognito assigns them a new session cookie. This parameter can also
        /// be forwarded to your IdPs. IdPs that accept this parameter also request a new authentication
        /// attempt from the user.
        case login

        /// This value has no effect on local sign-in and must be submitted in requests that redirect to IdPs.
        /// When included in your authorization request, this parameter adds prompt=select_account to the URL
        /// path for the IdP redirect destination. When IdPs support this parameter, they request that users
        /// select the account that they want to log in with.
        case selectAccount = "select_account"

        /// This value has no effect on local sign-in and must be submitted in requests that redirect to IdPs.
        /// When included in your authorization request, this parameter adds prompt=consent to the URL path for
        /// the IdP redirect destination. When IdPs support this parameter, they request user consent before
        /// they redirect back to your user pool.
        case consent
    }
}

public extension AuthWebUISignInRequest.Options {

    static func preferPrivateSession() -> AuthWebUISignInRequest.Options {
        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInRequest.Options(pluginOptions: pluginOptions)
        return options
    }
}
#endif
