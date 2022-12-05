//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension SignUpOutputResponse: Codable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
        case userConfirmed = "UserConfirmed"
        case userSub = "UserSub"
    }

    public init (from decoder: Swift.Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let userConfirmedDecoded = try containerValues.decode(Swift.Bool.self, forKey: .userConfirmed)
        userConfirmed = userConfirmedDecoded
        let codeDeliveryDetailsDecoded = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType.self, forKey: .codeDeliveryDetails)
        codeDeliveryDetails = codeDeliveryDetailsDecoded
        let userSubDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .userSub)
        userSub = userSubDecoded
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("This implementation is not needed")
    }
}
