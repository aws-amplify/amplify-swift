//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Payload data structure to send to the API Gateway endpoint
// for password sign up and sign in flow to initiate creating a new user
struct PreInitiateAuthSignUpPayload: Codable {
    let username: String
    let deliveryMedium: String
    let userAttributes: [String:String]?
    
    let userPoolId: String
    let region: String
    
    init(
        username: String,
        deliveryMedium: String,
        userAttributes: [String : String]?,
        userPoolId: String, region: String
    ) {
        self.username = username
        self.deliveryMedium = deliveryMedium
        self.userAttributes = userAttributes
        self.userPoolId = userPoolId
        self.region = region
    }
}
