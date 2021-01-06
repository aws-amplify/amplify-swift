//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthProvider {

    func toCognitoHostedUIString() -> String {
        switch self {
        case .amazon:
            return "LoginWithAmazon"
        case .apple:
            return "SignInWithApple"
        case .facebook:
            return "Facebook"
        case .google:
            return "Google"
        case .oidc:
            return "OIDC"
        case .saml:
            return "SAML"
        case .custom(let provider):
            return provider
        }
    }
}
