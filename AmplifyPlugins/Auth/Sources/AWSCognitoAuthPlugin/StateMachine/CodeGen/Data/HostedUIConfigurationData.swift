//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct HostedUIConfigurationData: Equatable {

    // User pool app cliend id configured for the HostedUI
    let clientId: String

    // Userpool app client secret configured for the HostedUI
    let clientSecret: String?

    // OAuth related information
    let oauth: OAuthConfigurationData

    init(clientId: String,
                oauth: OAuthConfigurationData,
                clientSecret: String? = nil) {
        self.clientId = clientId
        self.oauth = oauth
        self.clientSecret = clientSecret
    }
}

extension HostedUIConfigurationData: Codable { }

extension HostedUIConfigurationData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "clientId": clientId.masked(interiorCount: 4, retainingCount: 4),
            "clientSecret": clientSecret.masked(interiorCount: 4, retainingCount: 4),
            "oauth": oauth.debugDescription
        ]
    }
}

extension HostedUIConfigurationData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

struct OAuthConfigurationData: Equatable {
    let domain: String
    let scopes: [String]
    let signInRedirectURI: String
    let signOutRedirectURI: String

    init(domain: String,
         scopes: [String],
         signInRedirectURI: String,
         signOutRedirectURI: String) {
        self.domain = domain
        self.scopes = scopes
        self.signInRedirectURI = signInRedirectURI
        self.signOutRedirectURI = signOutRedirectURI
    }
}

extension OAuthConfigurationData: Codable { }

extension OAuthConfigurationData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "domain": domain.masked(interiorCount: 4, retainingCount: 4),
            "signInRedirectURI": signInRedirectURI.masked(interiorCount: 4, retainingCount: 4),
            "signOutRedirectURI": signOutRedirectURI.masked(interiorCount: 4, retainingCount: 4)
        ]
    }
}

extension OAuthConfigurationData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
