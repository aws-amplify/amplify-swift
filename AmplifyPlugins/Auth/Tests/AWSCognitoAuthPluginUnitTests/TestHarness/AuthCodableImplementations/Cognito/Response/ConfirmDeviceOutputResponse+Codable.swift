//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension ConfirmDeviceOutputResponse: Codable {

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case userConfirmationNecessary = "UserConfirmationNecessary"
    }

    public init (from decoder: Swift.Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let userConfirmationNecessaryDecoded = try containerValues.decode(Swift.Bool.self, forKey: .userConfirmationNecessary)
        userConfirmationNecessary = userConfirmationNecessaryDecoded
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not supported")
    }

}
