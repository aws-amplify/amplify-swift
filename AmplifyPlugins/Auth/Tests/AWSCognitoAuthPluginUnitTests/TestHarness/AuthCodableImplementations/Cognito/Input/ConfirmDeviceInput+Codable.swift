//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import AWSCognitoIdentity
import ClientRuntime

extension ConfirmDeviceInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case accessToken
        case deviceKey
        case deviceName
        case deviceSecretVerifierConfig
        case passwordVerifier
        case salt
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nestedChild = try values.nestedContainer(keyedBy: CodingKeys.self, forKey: .deviceSecretVerifierConfig)
        let accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
        let deviceKey = try values.decodeIfPresent(String.self, forKey: .deviceKey)
        let deviceName = try values.decodeIfPresent(String.self, forKey: .deviceName)
        let passwordVerifier = try nestedChild.decodeIfPresent(String.self, forKey: .passwordVerifier)
        let salt = try nestedChild.decodeIfPresent(String.self, forKey: .salt)
        self.init(
            accessToken: accessToken,
            deviceKey: deviceKey,
            deviceName: deviceName,
            deviceSecretVerifierConfig: .init(
                passwordVerifier: passwordVerifier,
                salt: salt)
        )
    }
}
