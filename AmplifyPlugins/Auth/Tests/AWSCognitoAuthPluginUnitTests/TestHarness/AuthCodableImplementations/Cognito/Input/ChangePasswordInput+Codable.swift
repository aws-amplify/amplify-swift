//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension ChangePasswordInput: Decodable {
    public init(from decoder: Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        previousPassword = try containerValues.decodeIfPresent(String.self, forKey: .previousPassword)
        proposedPassword = try containerValues.decodeIfPresent(String.self, forKey: .proposedPassword)
        accessToken = try containerValues.decodeIfPresent(String.self, forKey: .accessToken)
    }
}
