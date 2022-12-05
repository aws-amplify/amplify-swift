//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import AWSCognitoIdentity
import ClientRuntime

extension GetCredentialsForIdentityInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case logins
        case identityId
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let logins = try values.decodeIfPresent([String: String].self, forKey: .logins)
        let identityId = try values.decodeIfPresent(String.self, forKey: .identityId)
        self.init(identityId: identityId, logins: logins)
    }
}
