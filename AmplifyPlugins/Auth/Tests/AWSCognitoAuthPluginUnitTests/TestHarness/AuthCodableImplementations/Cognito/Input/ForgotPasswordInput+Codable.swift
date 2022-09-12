//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension ForgotPasswordInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case username
        case clientId
        case clientMetadata
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let username = try values.decode(String.self, forKey: .username)
        let clientId = try values.decode(String.self, forKey: .clientId)
        let clientMetadata = try values.decode([String: String].self, forKey: .clientMetadata)

        self.init(
            clientId: clientId,
            clientMetadata: clientMetadata,
            username: username)

    }
}
