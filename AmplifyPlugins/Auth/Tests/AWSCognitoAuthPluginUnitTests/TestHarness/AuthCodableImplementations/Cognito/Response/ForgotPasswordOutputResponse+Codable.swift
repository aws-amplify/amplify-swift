//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension ForgotPasswordOutputResponse: Codable {

    enum CodingKeys: Swift.String, Swift.CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
    }

    public init(from decoder: Swift.Decoder) throws {
        self.init()
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let codeDeliveryDetailsDecoded = try containerValues.decodeIfPresent(CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType.self, forKey: .codeDeliveryDetails)
        codeDeliveryDetails = codeDeliveryDetailsDecoded
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not supported")
    }

}
