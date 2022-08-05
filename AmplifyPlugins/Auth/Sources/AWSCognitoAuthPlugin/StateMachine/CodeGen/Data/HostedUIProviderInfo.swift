//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct HostedUIProviderInfo: Equatable {

    let authProvider: AuthProvider?

    let idpIdentifier: String?

    let federationProviderName: String?
}

extension HostedUIProviderInfo: Codable {

    enum CodingKeys: String, CodingKey {

        case idpIdentifier

        case federationProviderName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        idpIdentifier = try values.decode(String.self, forKey: .idpIdentifier)
        federationProviderName = try values.decode(String.self, forKey: .federationProviderName)
        authProvider = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idpIdentifier, forKey: .idpIdentifier)
        try container.encode(federationProviderName, forKey: .federationProviderName)
    }
}

extension AuthProvider: Equatable {
    public static func == (lhs: AuthProvider, rhs: AuthProvider) -> Bool {
        switch (lhs, rhs) {
        case (.amazon, .amazon),
            (.apple, .apple),
            (.facebook, .facebook),
            (.google, .google),
            (.oidc, .oidc),
            (.saml, .saml):
            return true
        case (.custom(let lhsCustom), .custom(let rhsCustom)):
            return lhsCustom == rhsCustom
        default:
            return false
        }
    }
}
