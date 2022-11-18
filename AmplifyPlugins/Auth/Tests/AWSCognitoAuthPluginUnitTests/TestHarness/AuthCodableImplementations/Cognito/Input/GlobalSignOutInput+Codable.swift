//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension GlobalSignOutInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case accessToken
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)


        self.init(accessToken: accessToken)

    }
}
