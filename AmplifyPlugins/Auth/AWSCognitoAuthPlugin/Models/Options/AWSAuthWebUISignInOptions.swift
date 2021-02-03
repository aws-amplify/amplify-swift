//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSAuthWebUISignInOptions {

    /// Identifier of the underlying authentication provider
    ///
    /// This can be used to identify a provider if there are multiple instance of the same authentication provider.
    /// For example if you have multiple SAML identity providers, you can identify one of them by providing this
    /// `idpIdentifier` value. If this value is set, the webUI will just show a textbox to enter the email address.
    /// On the other hand, if you do not give any value here, the webUI will show the list of identity providers and the
    /// user must select one of them to continue.
    public let idpIdentifier: String?

    /// Provider name to which the signedIn user will be federated in the AWS Cognito Identity Pool
    ///
    /// `federationProviderName` is required if you are signIn directly with a third party provider. For example if you
    /// are using Auth0, specify the `federationProviderName` as <your_domain>.auth0.com.
    public let federationProviderName: String?

    /// Starts the webUI signin in a private browser session, if supported by the current browser.
    ///
    /// Note that this value internally sets `prefersEphemeralWebBrowserSession` in ASWebAuthenticationSession.
    /// As per Apple documentation, Whether the request is honored depends on the user’s default web browser.
    /// Safari always honors the request.
    public let preferPrivateSession: Bool

    public init(idpIdentifier: String? = nil,
                federationProviderName: String? = nil,
                preferPrivateSession: Bool = false) {
        self.idpIdentifier = idpIdentifier
        self.federationProviderName = federationProviderName
        self.preferPrivateSession = preferPrivateSession
    }
}

extension AuthWebUISignInRequest.Options {

    public static func preferPrivateSession() -> AuthWebUISignInOperation.Request.Options {
        let pluginOptions = AWSAuthWebUISignInOptions(preferPrivateSession: true)
        let options = AuthWebUISignInOperation.Request.Options(pluginOptions: pluginOptions)
        return options
    }
}
