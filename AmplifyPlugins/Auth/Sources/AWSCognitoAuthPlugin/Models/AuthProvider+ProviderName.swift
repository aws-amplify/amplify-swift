//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AuthProvider {

    var providerName: String {

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

}
