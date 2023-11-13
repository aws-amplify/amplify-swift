//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSCognitoAuthPlugin

extension ConfirmDeviceInput: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        deviceSecretVerifierConfig = try values.decodeIfPresent(CognitoIdentityProviderClientTypes.DeviceSecretVerifierConfigType.self, forKey: .deviceSecretVerifierConfig)
        accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
        deviceKey = try values.decodeIfPresent(String.self, forKey: .deviceKey)
        deviceName = try values.decodeIfPresent(String.self, forKey: .deviceName)
    }
}
