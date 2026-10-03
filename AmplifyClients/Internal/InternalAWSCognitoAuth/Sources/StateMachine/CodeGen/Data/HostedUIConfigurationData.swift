//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct HostedUIConfigurationData: Equatable {

    // User pool app cliend id configured for the HostedUI
    package let clientId: String

    // Userpool app client secret configured for the HostedUI
    package let clientSecret: String?

    // OAuth related information
    package let oauth: OAuthConfigurationData

    package init(
        clientId: String,
        oauth: OAuthConfigurationData,
        clientSecret: String? = nil
    ) {
        self.clientId = clientId
        self.oauth = oauth
        self.clientSecret = clientSecret
    }
}

extension HostedUIConfigurationData: Codable { }

extension HostedUIConfigurationData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "clientId": clientId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "clientSecret": clientSecret.maskedForLog(interiorCount: 4, retainingCount: 4),
            "oauth": oauth.debugDescription
        ]
    }
}

extension HostedUIConfigurationData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

package struct OAuthConfigurationData: Equatable {
    package let domain: String
    package let scopes: [String]
    package let signInRedirectURI: String
    package let signOutRedirectURI: String

    package init(
        domain: String,
        scopes: [String],
        signInRedirectURI: String,
        signOutRedirectURI: String
    ) {
        self.domain = domain
        self.scopes = scopes
        self.signInRedirectURI = signInRedirectURI
        self.signOutRedirectURI = signOutRedirectURI
    }
}

extension OAuthConfigurationData: Codable { }

extension OAuthConfigurationData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "domain": domain.maskedForLog(interiorCount: 4, retainingCount: 4),
            "signInRedirectURI": signInRedirectURI.maskedForLog(interiorCount: 4, retainingCount: 4),
            "signOutRedirectURI": signOutRedirectURI.maskedForLog(interiorCount: 4, retainingCount: 4)
        ]
    }
}

extension OAuthConfigurationData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

// Plain values.
extension HostedUIConfigurationData: Sendable { }

extension OAuthConfigurationData: Sendable { }
