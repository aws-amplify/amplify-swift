//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct HostedUIConfigurationData: Equatable {

    // User pool app cliend id configured for the HostedUI
    public let clientId: String

    // Userpool app client secret configured for the HostedUI
    public let clientSecret: String?

    // OAuth related information
    public let oauth: OAuthConfigurationData

    public init(clientId: String,
                oauth: OAuthConfigurationData,
                clientSecret: String? = nil) {
        self.clientId = clientId
        self.oauth = oauth
        self.clientSecret = clientSecret
    }
}

extension HostedUIConfigurationData: Codable { }

extension HostedUIConfigurationData: CustomDebugDictionaryConvertible {
    public var debugDictionary: [String: Any] {
        [
            "clientId": clientId.masked(interiorCount: 4, retainingCount: 4),
            "clientSecret": clientSecret.masked(interiorCount: 4, retainingCount: 4),
            "oauth": oauth.debugDescription
        ]
    }
}

extension HostedUIConfigurationData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}

public struct OAuthConfigurationData: Equatable {
    public let domain: String
    public let scopes: [String]
    public let signInRedirectURI: String
    public let signOutRedirectURI: String

    public init(domain: String,
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
    public var debugDictionary: [String: Any] {
        [
            "domain": domain.masked(interiorCount: 4, retainingCount: 4),
            "signInRedirectURI": signInRedirectURI.masked(interiorCount: 4, retainingCount: 4),
            "signOutRedirectURI": signOutRedirectURI.masked(interiorCount: 4, retainingCount: 4)
        ]
    }
}

extension OAuthConfigurationData: CustomDebugStringConvertible {
    public var debugDescription: String {
        debugDictionary.debugDescription
    }
}
