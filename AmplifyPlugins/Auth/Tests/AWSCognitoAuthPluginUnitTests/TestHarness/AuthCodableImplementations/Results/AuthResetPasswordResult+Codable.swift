//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import Amplify

extension AuthResetPasswordResult: Codable {
    enum CodingKeys: String, CodingKey {
        case isPasswordReset
        case nextStep
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let isPasswordReset = try values.decode(Bool.self, forKey: .isPasswordReset)
        let resetPasswordStep = try values.decode(AuthResetPasswordStep.self, forKey: .nextStep)
        self.init(isPasswordReset: isPasswordReset,
                  nextStep: resetPasswordStep)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }
}

extension AuthResetPasswordStep: Codable {

    enum CodingKeys: String, CodingKey {
        case resetPasswordStep
        case codeDeliveryDetails
        case additionalInfo
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if try values.decode(String.self, forKey: .resetPasswordStep) == "DONE" {
            self = .done
        } else if try values.decode(String.self, forKey: .resetPasswordStep) == "CONFIRM_RESET_PASSWORD_WITH_CODE" {

            let codeDeliveryDetails = try values.decode(
                AuthCodeDeliveryDetails.self,
                forKey: .codeDeliveryDetails)
            let additionalInfo = try values.decode(
                AdditionalInfo.self,
                forKey: .additionalInfo)
            self = .confirmResetPasswordWithCode(
                codeDeliveryDetails,
                additionalInfo)
        } else {
            fatalError("next step type not supported")
        }

    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }

}

extension AuthCodeDeliveryDetails: Codable {

    enum CodingKeys: String, CodingKey {
        case destination
        case deliveryMedium
        case attributeName
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let destinationDescription = try values.decode(String.self, forKey: .destination)
        let deliveryMedium = try values.decode(String.self, forKey: .deliveryMedium)

        let destination: DeliveryDestination
        var attributeKey: AuthUserAttributeKey? = nil

        if deliveryMedium == "EMAIL" {
            destination = .email(destinationDescription)
        } else if deliveryMedium == "SMS"{
            destination = .sms(destinationDescription)
        }  else {
            fatalError()
        }

        let attributeName = try values.decodeIfPresent(String.self, forKey: .attributeName)
        if attributeName == "EMAIL" {
            attributeKey = .email
        } else if let attributeName = attributeName  {
            attributeKey = .unknown(attributeName)
        }

        self.init(destination: destination,
                  attributeKey: attributeKey)
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not Supported")
    }
}
