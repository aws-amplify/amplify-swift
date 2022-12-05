//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import ClientRuntime

extension GetCredentialsForIdentityOutputResponse: Codable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case credentials = "Credentials"
        case identityId = "IdentityId"
    }

    public init (from decoder: Swift.Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let identityIdDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .identityId)
        identityId = identityIdDecoded
        let credentialsDecoded = try containerValues.decodeIfPresent(CognitoIdentityClientTypes.Credentials.self, forKey: .credentials)
        credentials = credentialsDecoded
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("This implementation is not needed")
    }
}
