//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct HostedUIOptions {

    let scopes: [String]

    let providerInfo: HostedUIProviderInfo

    let presentationAnchor: AuthUIPresentationAnchor?

    let preferPrivateSession: Bool

    let nonce: String?

    let language: String?

    let loginHint: String?

    let prompt: String?

    let resource: String?
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

    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
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

#if os(iOS) || os(macOS) || os(visionOS)
extension HostedUIOptions {
    init(
        scopes: [String],
        providerInfo: HostedUIProviderInfo,
        presentationAnchor: AuthUIPresentationAnchor?,
        preferPrivateSession: Bool,
        nonce: String?,
        language: String?,
        loginHint: String?,
        promptValues: [AWSAuthWebUISignInOptions.Prompt]?,
        resource: String?
    ) {
        self.init(
            scopes: scopes,
            providerInfo: providerInfo,
            presentationAnchor: presentationAnchor,
            preferPrivateSession: preferPrivateSession,
            nonce: nonce,
            language: language,
            loginHint: loginHint,
            prompt: promptValues?.map { "\($0.rawValue)" }.joined(separator: " "),
            resource: resource
        )
    }
}
#endif
