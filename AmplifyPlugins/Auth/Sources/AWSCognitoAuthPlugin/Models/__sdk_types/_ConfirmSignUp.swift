//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Represents the request to confirm registration of a user.
struct ConfirmSignUpInput: Equatable, Encodable {
    /// The Amazon Pinpoint analytics metadata for collecting metrics for ConfirmSignUp calls.
    var analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    /// The ID of the app client associated with the user pool.
    /// This member is required.
    var clientId: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the ConfirmSignUp API action, Amazon Cognito invokes the function that is assigned to the post confirmation trigger. When Amazon Cognito invokes this function, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your ConfirmSignUp request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// The confirmation code sent by a user's request to confirm registration.
    /// This member is required.
    var confirmationCode: String?
    /// Boolean to be specified to force user confirmation irrespective of existing alias. By default set to False. If this parameter is set to True and the phone number/email used for sign up confirmation already exists as an alias with a different user, the API call will migrate the alias from the previous user to the newly created user being confirmed. If set to False, the API will throw an AliasExistsException error.
    var forceAliasCreation: Bool?
    /// A keyed-hash message authentication code (HMAC) calculated using the secret key of a user pool client and username plus the client ID in the message.
    var secretHash: String?
    /// Contextual data about your user session, such as the device fingerprint, IP address, or location. Amazon Cognito advanced security evaluates the risk of an authentication event based on the context that your app generates and passes to Amazon Cognito when it makes API requests.
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
    /// The user name of the user whose registration you want to confirm.
    /// This member is required.
    var username: String?

    enum CodingKeys: String, CodingKey {
        case analyticsMetadata = "AnalyticsMetadata"
        case clientId = "ClientId"
        case clientMetadata = "ClientMetadata"
        case confirmationCode = "ConfirmationCode"
        case forceAliasCreation = "ForceAliasCreation"
        case secretHash = "SecretHash"
        case userContextData = "UserContextData"
        case username = "Username"
    }
}

/// Represents the response from the server for the registration confirmation.
struct ConfirmSignUpOutputResponse: Equatable, Decodable {

    init() { }
}
