//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AuthProvider {

    var userPoolProviderName: String {
        switch self {
        case .amazon:
            return "LoginWithAmazon"
        case .apple:
            return "SignInWithApple"
        case .facebook:
            return "Facebook"
        case .google:
            return "Google"
        case .twitter:
            return "Twitter"
        case .oidc(let providerName),
             .saml(let providerName),
             .custom(let providerName):
            return providerName
        }
    }

    var identityPoolProviderName: String {
        switch self {
        case .amazon:
            return "www.amazon.com"
        case .apple:
            return "appleid.apple.com"
        case .facebook:
            return "graph.facebook.com"
        case .google:
            return "accounts.google.com"
        case .twitter:
            return "api.twitter.com"
        case .oidc(let providerName),
             .saml(let providerName),
             .custom(let providerName):
            return providerName
        }
    }

    init(identityPoolProviderName: String) {
        switch identityPoolProviderName {
        case "www.amazon.com":
            self = .amazon
        case "appleid.apple.com":
            self = .apple
        case "graph.facebook.com":
            self = .facebook
        case "accounts.google.com":
            self = .google
        case "api.twitter.com":
            self = .twitter
        default:
            self = .oidc(identityPoolProviderName)
        }

    }
}
