//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// Initiates the authentication request.
struct InitiateAuthInput: Equatable {
    /// The Amazon Pinpoint analytics metadata that contributes to your metrics for InitiateAuth calls.
    var analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    /// The authentication flow for this call to run. The API action will depend on this value. For example:
    ///
    /// * REFRESH_TOKEN_AUTH takes in a valid refresh token and returns new tokens.
    ///
    /// * USER_SRP_AUTH takes in USERNAME and SRP_A and returns the SRP variables to be used for next challenge execution.
    ///
    /// * USER_PASSWORD_AUTH takes in USERNAME and PASSWORD and returns the next challenge or tokens.
    ///
    ///
    /// Valid values include:
    ///
    /// * USER_SRP_AUTH: Authentication flow for the Secure Remote Password (SRP) protocol.
    ///
    /// * REFRESH_TOKEN_AUTH/REFRESH_TOKEN: Authentication flow for refreshing the access token and ID token by supplying a valid refresh token.
    ///
    /// * CUSTOM_AUTH: Custom authentication flow.
    ///
    /// * USER_PASSWORD_AUTH: Non-SRP authentication flow; user name and password are passed directly. If a user migration Lambda trigger is set, this flow will invoke the user migration Lambda if it doesn't find the user name in the user pool.
    ///
    ///
    /// ADMIN_NO_SRP_AUTH isn't a valid value.
    /// This member is required.
    var authFlow: CognitoIdentityProviderClientTypes.AuthFlowType?
    /// The authentication parameters. These are inputs corresponding to the AuthFlow that you're invoking. The required values depend on the value of AuthFlow:
    ///
    /// * For USER_SRP_AUTH: USERNAME (required), SRP_A (required), SECRET_HASH (required if the app client is configured with a client secret), DEVICE_KEY.
    ///
    /// * For USER_PASSWORD_AUTH: USERNAME (required), PASSWORD (required), SECRET_HASH (required if the app client is configured with a client secret), DEVICE_KEY.
    ///
    /// * For REFRESH_TOKEN_AUTH/REFRESH_TOKEN: REFRESH_TOKEN (required), SECRET_HASH (required if the app client is configured with a client secret), DEVICE_KEY.
    ///
    /// * For CUSTOM_AUTH: USERNAME (required), SECRET_HASH (if app client is configured with client secret), DEVICE_KEY. To start the authentication flow with password verification, include ChallengeName: SRP_A and SRP_A: (The SRP_A Value).
    ///
    ///
    /// For more information about SECRET_HASH, see [Computing secret hash values](https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash). For information about DEVICE_KEY, see [Working with user devices in your user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-device-tracking.html).
    var authParameters: [String:String]?
    /// The app client ID.
    /// This member is required.
    var clientId: String?
    /// A map of custom key-value pairs that you can provide as input for certain custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the InitiateAuth API action, Amazon Cognito invokes the Lambda functions that are specified for various triggers. The ClientMetadata value is passed as input to the functions for only the following triggers:
    ///
    /// * Pre signup
    ///
    /// * Pre authentication
    ///
    /// * User migration
    ///
    ///
    /// When Amazon Cognito invokes the functions for these triggers, it passes a JSON payload, which the function receives as input. This payload contains a validationData attribute, which provides the data that you assigned to the ClientMetadata parameter in your InitiateAuth request. In your function code in Lambda, you can process the validationData value to enhance your workflow for your specific needs. When you use the InitiateAuth API action, Amazon Cognito also invokes the functions for the following triggers, but it doesn't provide the ClientMetadata value as input:
    ///
    /// * Post authentication
    ///
    /// * Custom message
    ///
    /// * Pre token generation
    ///
    /// * Create auth challenge
    ///
    /// * Define auth challenge
    ///
    /// * Verify auth challenge
    ///
    ///
    /// For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// Contextual data about your user session, such as the device fingerprint, IP address, or location. Amazon Cognito advanced security evaluates the risk of an authentication event based on the context that your app generates and passes to Amazon Cognito when it makes API requests.
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?

    enum CodingKeys: String, CodingKey {
        case analyticsMetadata = "AnalyticsMetadata"
        case authFlow = "AuthFlow"
        case authParameters = "AuthParameters"
        case clientId = "ClientId"
        case clientMetadata = "ClientMetadata"
        case userContextData = "UserContextData"
    }
}


/// Initiates the authentication response.
struct InitiateAuthOutputResponse: Equatable {
    /// The result of the authentication response. This result is only returned if the caller doesn't need to pass another challenge. If the caller does need to pass another challenge before it gets tokens, ChallengeName, ChallengeParameters, and Session are returned.
    var authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType?
    /// The name of the challenge that you're responding to with this call. This name is returned in the AdminInitiateAuth response if you must pass another challenge. Valid values include the following: All of the following challenges require USERNAME and SECRET_HASH (if applicable) in the parameters.
    ///
    /// * SMS_MFA: Next challenge is to supply an SMS_MFA_CODE, delivered via SMS.
    ///
    /// * PASSWORD_VERIFIER: Next challenge is to supply PASSWORD_CLAIM_SIGNATURE, PASSWORD_CLAIM_SECRET_BLOCK, and TIMESTAMP after the client-side SRP calculations.
    ///
    /// * CUSTOM_CHALLENGE: This is returned if your custom authentication flow determines that the user should pass another challenge before tokens are issued.
    ///
    /// * DEVICE_SRP_AUTH: If device tracking was activated on your user pool and the previous challenges were passed, this challenge is returned so that Amazon Cognito can start tracking this device.
    ///
    /// * DEVICE_PASSWORD_VERIFIER: Similar to PASSWORD_VERIFIER, but for devices only.
    ///
    /// * NEW_PASSWORD_REQUIRED: For users who are required to change their passwords after successful first login. Respond to this challenge with NEW_PASSWORD and any required attributes that Amazon Cognito returned in the requiredAttributes parameter. You can also set values for attributes that aren't required by your user pool and that your app client can write. For more information, see [RespondToAuthChallenge](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_RespondToAuthChallenge.html). In a NEW_PASSWORD_REQUIRED challenge response, you can't modify a required attribute that already has a value. In RespondToAuthChallenge, set a value for any keys that Amazon Cognito returned in the requiredAttributes parameter, then use the UpdateUserAttributes API operation to modify the value of any additional attributes.
    ///
    /// * MFA_SETUP: For users who are required to setup an MFA factor before they can sign in. The MFA types activated for the user pool will be listed in the challenge parameters MFA_CAN_SETUP value. To set up software token MFA, use the session returned here from InitiateAuth as an input to AssociateSoftwareToken. Use the session returned by VerifySoftwareToken as an input to RespondToAuthChallenge with challenge name MFA_SETUP to complete sign-in. To set up SMS MFA, an administrator should help the user to add a phone number to their account, and then the user should call InitiateAuth again to restart sign-in.
    var challengeName: CognitoIdentityProviderClientTypes.ChallengeNameType?
    /// The challenge parameters. These are returned in the InitiateAuth response if you must pass another challenge. The responses in this parameter should be used to compute inputs to the next call (RespondToAuthChallenge). All challenges require USERNAME and SECRET_HASH (if applicable).
    var challengeParameters: [String:String]?
    /// The session that should pass both ways in challenge-response calls to the service. If the caller must pass another challenge, they return a session with other challenge parameters. This session should be passed as it is to the next RespondToAuthChallenge API call.
    var session: String?

    enum CodingKeys: String, CodingKey {
        case authenticationResult = "AuthenticationResult"
        case challengeName = "ChallengeName"
        case challengeParameters = "ChallengeParameters"
        case session = "Session"
    }
}
