//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

struct GetUserAttributeVerificationCodeInput: Equatable, Encodable {
    /// A non-expired access token for the user whose attribute verification code you want to generate.
    /// This member is required.
    var accessToken: String?
    /// The attribute name returned by the server response to get the user attribute verification code.
    /// This member is required.
    var attributeName: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the GetUserAttributeVerificationCode API action, Amazon Cognito invokes the function that is assigned to the custom message trigger. When Amazon Cognito invokes this function, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your GetUserAttributeVerificationCode request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case attributeName = "AttributeName"
        case clientMetadata = "ClientMetadata"
    }
}

/// The verification code response returned by the server response to get the user attribute verification code.
struct GetUserAttributeVerificationCodeOutputResponse: Equatable, Decodable {
    /// The code delivery details returned by the server in response to the request to get the user attribute verification code.
    var codeDeliveryDetails: CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType?

    enum CodingKeys: String, CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
    }
}
