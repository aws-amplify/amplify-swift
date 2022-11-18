//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import AWSCognitoIdentity
import ClientRuntime

extension GetIdInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case logins
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let logins = try values.decodeIfPresent([String: String].self, forKey: .logins)
        self.init(logins: logins)
    }
}
