//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to register a user.
struct SignUpInput: Equatable {
    /// The Amazon Pinpoint analytics metadata that contributes to your metrics for SignUp calls.
    var analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    /// The ID of the client associated with the user pool.
    /// This member is required.
    var clientId: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the SignUp API action, Amazon Cognito invokes any functions that are assigned to the following triggers: pre sign-up, custom message, and post confirmation. When Amazon Cognito invokes any of these functions, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your SignUp request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// The password of the user you want to register.
    /// This member is required.
    var password: String?
    /// A keyed-hash message authentication code (HMAC) calculated using the secret key of a user pool client and username plus the client ID in the message.
    var secretHash: String?
    /// An array of name-value pairs representing user attributes. For custom attributes, you must prepend the custom: prefix to the attribute name.
    var userAttributes: [CognitoIdentityProviderClientTypes.AttributeType]?
    /// Contextual data about your user session, such as the device fingerprint, IP address, or location. Amazon Cognito advanced security evaluates the risk of an authentication event based on the context that your app generates and passes to Amazon Cognito when it makes API requests.
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
    /// The user name of the user you want to register.
    /// This member is required.
    var username: String?
    /// The validation data in the request to register a user.
    var validationData: [CognitoIdentityProviderClientTypes.AttributeType]?

    enum CodingKeys: String, CodingKey {
        case analyticsMetadata = "AnalyticsMetadata"
        case clientId = "ClientId"
        case clientMetadata = "ClientMetadata"
        case password = "Password"
        case secretHash = "SecretHash"
        case userAttributes = "UserAttributes"
        case userContextData = "UserContextData"
        case username = "Username"
        case validationData = "ValidationData"
    }
}

/// The response from the server for a registration request.
struct SignUpOutputResponse: Equatable {
    /// The code delivery details returned by the server response to the user registration request.
    var codeDeliveryDetails: CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType?
    /// A response from the server indicating that a user registration has been confirmed.
    /// This member is required.
    var userConfirmed: Bool
    /// The UUID of the authenticated user. This isn't the same as username.
    /// This member is required.
    var userSub: String?

    enum CodingKeys: String, CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
        case userConfirmed = "UserConfirmed"
        case userSub = "UserSub"
    }
}
