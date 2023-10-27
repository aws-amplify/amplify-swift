//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to update user attributes.
struct UpdateUserAttributesInput: Equatable, Encodable {
    /// A valid access token that Amazon Cognito issued to the user whose user attributes you want to update.
    /// This member is required.
    var accessToken: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action initiates. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the UpdateUserAttributes API action, Amazon Cognito invokes the function that is assigned to the custom message trigger. When Amazon Cognito invokes this function, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your UpdateUserAttributes request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// An array of name-value pairs representing user attributes. For custom attributes, you must prepend the custom: prefix to the attribute name. If you have set an attribute to require verification before Amazon Cognito updates its value, this request doesn’t immediately update the value of that attribute. After your user receives and responds to a verification message to verify the new value, Amazon Cognito updates the attribute value. Your user can sign in and receive messages with the original attribute value until they verify the new value.
    /// This member is required.
    var userAttributes: [CognitoIdentityProviderClientTypes.AttributeType]?

    enum CodingKeys: String, CodingKey {
        case accessToken = "AccessToken"
        case clientMetadata = "ClientMetadata"
        case userAttributes = "UserAttributes"
    }
}

/// Represents the response from the server for the request to update user attributes.
struct UpdateUserAttributesOutputResponse: Equatable, Decodable {
    /// The code delivery details list from the server for the request to update user attributes.
    var codeDeliveryDetailsList: [CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType]?

    enum CodingKeys: String, CodingKey {
        case codeDeliveryDetailsList = "CodeDeliveryDetailsList"
    }
}
