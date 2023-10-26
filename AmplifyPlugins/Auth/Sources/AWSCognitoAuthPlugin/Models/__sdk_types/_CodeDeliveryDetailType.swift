//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    //The delivery details for an email or SMS message that Amazon Cognito sent for authentication or verification.
    struct CodeDeliveryDetailsType: Equatable {
        /// The name of the attribute that Amazon Cognito verifies with the code.
        var attributeName: String?
        //The method that Amazon Cognito used to send the code.
        var deliveryMedium: CognitoIdentityProviderClientTypes.DeliveryMediumType?
        ///The email address or phone number destination where Amazon Cognito sent the code.
        var destination: String?

        enum CodingKeys: String, CodingKey {
            case attributeName = "AttributeName"
            case deliveryMedium = "DeliveryMedium"
            case destination = "Destination"
        }
    }
}
