//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// Contextual data, such as the user's device fingerprint, IP address, or location, used for evaluating the risk of an unexpected event by Amazon Cognito advanced security.
    struct UserContextDataType: Equatable, Codable {
        /// Encoded device-fingerprint details that your app collected with the Amazon Cognito context data collection library. For more information, see [Adding user device and session data to API requests](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-settings-adaptive-authentication.html#user-pool-settings-adaptive-authentication-device-fingerprint).
        var encodedData: String?
        /// The source IP address of your user's device.
        var ipAddress: String?

        enum CodingKeys: String, CodingKey {
            case encodedData = "EncodedData"
            case ipAddress = "IpAddress"
        }
    }

}
