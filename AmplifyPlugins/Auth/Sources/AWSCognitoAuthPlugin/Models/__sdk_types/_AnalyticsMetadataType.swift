//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

extension CognitoIdentityProviderClientTypes {
    /// An Amazon Pinpoint analytics endpoint. An endpoint uniquely identifies a mobile device, email address, or phone number that can receive messages from Amazon Pinpoint analytics. For more information about Amazon Web Services Regions that can contain Amazon Pinpoint resources for use with Amazon Cognito user pools, see [Using Amazon Pinpoint analytics with Amazon Cognito user pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-pinpoint-integration.html).
    struct AnalyticsMetadataType: Equatable, Codable {
        /// The endpoint ID.
        var analyticsEndpointId: String?

        enum CodingKeys: String, CodingKey {
            case analyticsEndpointId = "AnalyticsEndpointId"
        }
    }
}
