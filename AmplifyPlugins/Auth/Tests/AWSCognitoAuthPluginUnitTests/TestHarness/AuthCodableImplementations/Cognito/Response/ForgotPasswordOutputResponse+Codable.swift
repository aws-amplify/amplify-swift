//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension ForgotPasswordOutput: Codable {

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
    }

    public init(from decoder: Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            codeDeliveryDetails: container.decodeIfPresent(
                CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType.self,
                forKey: .codeDeliveryDetails
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not supported")
    }

}

extension CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType: Decodable {
    private enum CodingKeys: String, CodingKey {
        case attributeName = "AttributeName"
        case deliveryMedium = "DeliveryMedium"
        case destination = "Destination"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            attributeName: container.decodeIfPresent(String.self, forKey: .attributeName),
            deliveryMedium: container.decodeIfPresent(
                CognitoIdentityProviderClientTypes.DeliveryMediumType.self,
                forKey: .deliveryMedium
            ),
            destination: container.decodeIfPresent(String.self, forKey: .destination)
        )
    }
}

extension CognitoIdentityProviderClientTypes.DeliveryMediumType: Decodable {}
