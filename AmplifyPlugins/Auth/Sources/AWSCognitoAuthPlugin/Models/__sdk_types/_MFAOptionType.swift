//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// This data type is no longer supported. Applies only to SMS multi-factor authentication (MFA) configurations. Does not apply to time-based one-time password (TOTP) software token MFA configurations.
    struct MFAOptionType: Equatable {
        /// The attribute name of the MFA option type. The only valid value is phone_number.
        var attributeName: String?
        /// The delivery medium to send the MFA code. You can use this parameter to set only the SMS delivery medium value.
        var deliveryMedium: CognitoIdentityProviderClientTypes.DeliveryMediumType?

        enum CodingKeys: String, CodingKey {
            case attributeName = "AttributeName"
            case deliveryMedium = "DeliveryMedium"
        }
    }

}
