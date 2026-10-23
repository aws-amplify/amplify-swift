//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.AuthProvider` and the engine's `EngineAuthProvider`.
// Case to case, with the payload passed through unchanged.

extension EngineAuthProvider {

    init(_ provider: AuthProvider) {
        switch provider {
        case .amazon: self = .amazon
        case .apple: self = .apple
        case .facebook: self = .facebook
        case .google: self = .google
        case .twitter: self = .twitter
        case .oidc(let name): self = .oidc(name)
        case .saml(let name): self = .saml(name)
        case .custom(let name): self = .custom(name)
        }
    }
}

extension AuthProvider {

    init(_ provider: EngineAuthProvider) {
        switch provider {
        case .amazon: self = .amazon
        case .apple: self = .apple
        case .facebook: self = .facebook
        case .google: self = .google
        case .twitter: self = .twitter
        case .oidc(let name): self = .oidc(name)
        case .saml(let name): self = .saml(name)
        case .custom(let name): self = .custom(name)
        }
    }
}
