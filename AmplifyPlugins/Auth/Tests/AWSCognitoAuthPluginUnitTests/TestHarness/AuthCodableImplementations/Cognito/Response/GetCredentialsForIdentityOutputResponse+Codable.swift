//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import ClientRuntime

extension GetCredentialsForIdentityOutput: Codable {
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

extension CognitoIdentityClientTypes.Credentials: Decodable {
    private enum CodingKeys: String, CodingKey {
        case accessKeyId = "AccessKeyId"
        case expiration = "Expiration"
        case secretKey = "SecretKey"
        case sessionToken = "SessionToken"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            accessKeyId: container.decodeIfPresent(String.self, forKey: .accessKeyId),
            expiration: container.decodeIfPresent(Date.self, forKey: .expiration),
            secretKey: container.decodeIfPresent(String.self, forKey: .secretKey),
            sessionToken: container.decodeIfPresent(String.self, forKey: .sessionToken)
        )
    }
}
