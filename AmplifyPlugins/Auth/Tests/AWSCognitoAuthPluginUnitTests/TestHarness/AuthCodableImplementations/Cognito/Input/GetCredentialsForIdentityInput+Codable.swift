//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension GetCredentialsForIdentityInput: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let logins = try values.decodeIfPresent([String: String].self, forKey: .logins)
        let identityId = try values.decodeIfPresent(String.self, forKey: .identityId)
        self.init(identityId: identityId, logins: logins)
    }
}
