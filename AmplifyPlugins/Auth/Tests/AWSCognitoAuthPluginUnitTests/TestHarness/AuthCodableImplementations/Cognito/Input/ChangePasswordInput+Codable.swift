//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

// Already conforms to encodable
extension ChangePasswordInput: Decodable {

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case previousPassword = "PreviousPassword"
        case proposedPassword = "ProposedPassword"
    }

    public init(from decoder: Decoder) throws {

        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let previousPasswordDecoded = try containerValues.decodeIfPresent(String.self, forKey: .previousPassword)
        let proposedPasswordDecoded = try containerValues.decodeIfPresent(String.self, forKey: .proposedPassword)
        let accessTokenDecoded = try containerValues.decodeIfPresent(String.self, forKey: .accessToken)

        self.init(
            accessToken: accessTokenDecoded,
            previousPassword: previousPasswordDecoded,
            proposedPassword: proposedPasswordDecoded)

    }
}
