//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore

struct AWSAuthConfiguration {
    let region: AWSRegionType

    let identityPoolId: String?

    let userPoolId: String?
    let userPoolAppClientId: String?
    let userPoolAppClientSecret: String?

    let authenticationFlowType: String?
    let userPoolHostedUIDomain: String?

    let signInRedirectURI: String?
    let signOutRedirectURI: String?

    let hostedUIScopes: [String]?
}

extension AWSAuthConfiguration: Decodable {

    enum CodingKeys: String, CodingKey {
        case region
        case identityPoolId

        case userPoolId
        case userPoolAppClientId
        case userPoolAppClientSecret

        case authenticationFlowType
        case userPoolHostedUIDomain

        case signInRedirectURI
        case signOutRedirectURI

        case hostedUIScopes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let regionString = try values.decode(String.self, forKey: .region) as NSString

        self.region = regionString.aws_regionTypeValue()
        self.identityPoolId = try values.decode(String.self, forKey: .identityPoolId)
        self.userPoolId = try values.decode(String.self, forKey: .userPoolId)
        self.userPoolAppClientId = try values.decode(String.self, forKey: .userPoolAppClientId)
        self.userPoolAppClientSecret = try values.decode(String.self, forKey: .userPoolAppClientSecret)
        self.authenticationFlowType = try values.decode(String.self, forKey: .authenticationFlowType)
        self.userPoolHostedUIDomain = try values.decode(String.self, forKey: .userPoolHostedUIDomain)
        self.signInRedirectURI = try values.decode(String.self, forKey: .signInRedirectURI)
        self.signOutRedirectURI = try values.decode(String.self, forKey: .signOutRedirectURI)
        self.hostedUIScopes = try values.decode(Array.self, forKey: .hostedUIScopes)
    }
}
