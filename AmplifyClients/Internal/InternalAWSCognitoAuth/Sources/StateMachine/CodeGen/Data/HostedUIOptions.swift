//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct HostedUIOptions {

    package let scopes: [String]

    package let providerInfo: HostedUIProviderInfo

    package let presentationAnchor: EnginePresentationAnchor?

    package let preferPrivateSession: Bool

    package let nonce: String?

    package let language: String?

    package let loginHint: String?

    package let prompt: String?

    package let resource: String?

    /// The memberwise initializer, as the compiler synthesized it before the move. The plugin's
    /// `[AWSAuthWebUISignInOptions.Prompt]` initializer delegates to it
    /// (`AWSCognitoAuthPlugin/Support/EngineBridge/HostedUIOptions+Prompt.swift`).
    package init(
        scopes: [String],
        providerInfo: HostedUIProviderInfo,
        presentationAnchor: EnginePresentationAnchor?,
        preferPrivateSession: Bool,
        nonce: String?,
        language: String?,
        loginHint: String?,
        prompt: String?,
        resource: String?
    ) {
        self.scopes = scopes
        self.providerInfo = providerInfo
        self.presentationAnchor = presentationAnchor
        self.preferPrivateSession = preferPrivateSession
        self.nonce = nonce
        self.language = language
        self.loginHint = loginHint
        self.prompt = prompt
        self.resource = resource
    }
}

extension HostedUIOptions: Codable {

    enum CodingKeys: String, CodingKey {

        case scopes

        case providerInfo

        case preferPrivateSession

        case nonce

        case language = "lang"

        case loginHint = "login_hint"

        case prompt

        case resource
    }

    package init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.scopes = try values.decode(Array.self, forKey: .scopes)
        self.providerInfo = try values.decode(HostedUIProviderInfo.self, forKey: .providerInfo)
        self.preferPrivateSession = try values.decode(Bool.self, forKey: .preferPrivateSession)
        self.presentationAnchor = nil
        self.nonce = try values.decodeIfPresent(String.self, forKey: .nonce)
        self.language = try values.decodeIfPresent(String.self, forKey: .language)
        self.loginHint = try values.decodeIfPresent(String.self, forKey: .loginHint)
        self.prompt = try values.decodeIfPresent(String.self, forKey: .prompt)
        self.resource = try values.decodeIfPresent(String.self, forKey: .resource)
    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scopes, forKey: .scopes)
        try container.encode(providerInfo, forKey: .providerInfo)
        try container.encode(preferPrivateSession, forKey: .preferPrivateSession)
        try container.encodeIfPresent(nonce, forKey: .nonce)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(loginHint, forKey: .loginHint)
        try container.encodeIfPresent(prompt, forKey: .prompt)
        try container.encodeIfPresent(resource, forKey: .resource)
    }
}

extension HostedUIOptions: Equatable { }
