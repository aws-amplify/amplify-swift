//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to resend the confirmation code.
struct ResendConfirmationCodeInput: Equatable {
    /// The Amazon Pinpoint analytics metadata that contributes to your metrics for ResendConfirmationCode calls.
    var analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    /// The ID of the client associated with the user pool.
    /// This member is required.
    var clientId: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the ResendConfirmationCode API action, Amazon Cognito invokes the function that is assigned to the custom message trigger. When Amazon Cognito invokes this function, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your ResendConfirmationCode request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// A keyed-hash message authentication code (HMAC) calculated using the secret key of a user pool client and username plus the client ID in the message.
    var secretHash: String?
    /// Contextual data about your user session, such as the device fingerprint, IP address, or location. Amazon Cognito advanced security evaluates the risk of an authentication event based on the context that your app generates and passes to Amazon Cognito when it makes API requests.
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
    /// The username attribute of the user to whom you want to resend a confirmation code.
    /// This member is required.
    var username: String?

    enum CodingKeys: String, CodingKey {
        case analyticsMetadata = "AnalyticsMetadata"
        case clientId = "ClientId"
        case clientMetadata = "ClientMetadata"
        case secretHash = "SecretHash"
        case userContextData = "UserContextData"
        case username = "Username"
    }
}


/// The response from the server when Amazon Cognito makes the request to resend a confirmation code.
struct ResendConfirmationCodeOutputResponse: Equatable {
    /// The code delivery details returned by the server in response to the request to resend the confirmation code.
    var codeDeliveryDetails: CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType?

    enum CodingKeys: String, CodingKey {
        case codeDeliveryDetails = "CodeDeliveryDetails"
    }
}
