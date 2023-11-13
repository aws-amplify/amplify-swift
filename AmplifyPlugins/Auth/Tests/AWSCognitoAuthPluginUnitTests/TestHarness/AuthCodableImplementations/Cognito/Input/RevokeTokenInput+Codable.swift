//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension RevokeTokenInput: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let token = try values.decodeIfPresent(String.self, forKey: .token)
        let clientId = try values.decodeIfPresent(String.self, forKey: .clientId)
        let clientSecret = try values.decodeIfPresent(String.self, forKey: .clientSecret)

        self.init(
            clientId: clientId,
            clientSecret: clientSecret,
            token: token
        )
    }
}
