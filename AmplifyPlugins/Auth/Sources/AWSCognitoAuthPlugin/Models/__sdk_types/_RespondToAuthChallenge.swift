//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/26/23.
//

import Foundation

/// The request to respond to an authentication challenge.
struct RespondToAuthChallengeInput: Equatable, Encodable {
    /// The Amazon Pinpoint analytics metadata that contributes to your metrics for RespondToAuthChallenge calls.
    var analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    /// The challenge name. For more information, see [InitiateAuth](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html). ADMIN_NO_SRP_AUTH isn't a valid value.
    /// This member is required.
    var challengeName: CognitoIdentityProviderClientTypes.ChallengeNameType?
    /// The challenge responses. These are inputs corresponding to the value of ChallengeName, for example: SECRET_HASH (if app client is configured with client secret) applies to all of the inputs that follow (including SOFTWARE_TOKEN_MFA).
    ///
    /// * SMS_MFA: SMS_MFA_CODE, USERNAME.
    ///
    /// * PASSWORD_VERIFIER: PASSWORD_CLAIM_SIGNATURE, PASSWORD_CLAIM_SECRET_BLOCK, TIMESTAMP, USERNAME. PASSWORD_VERIFIER requires DEVICE_KEY when you sign in with a remembered device.
    ///
    /// * NEW_PASSWORD_REQUIRED: NEW_PASSWORD, USERNAME, SECRET_HASH (if app client is configured with client secret). To set any required attributes that Amazon Cognito returned as requiredAttributes in the InitiateAuth response, add a userAttributes.attributename  parameter. This parameter can also set values for writable attributes that aren't required by your user pool. In a NEW_PASSWORD_REQUIRED challenge response, you can't modify a required attribute that already has a value. In RespondToAuthChallenge, set a value for any keys that Amazon Cognito returned in the requiredAttributes parameter, then use the UpdateUserAttributes API operation to modify the value of any additional attributes.
    ///
    /// * SOFTWARE_TOKEN_MFA: USERNAME and SOFTWARE_TOKEN_MFA_CODE are required attributes.
    ///
    /// * DEVICE_SRP_AUTH requires USERNAME, DEVICE_KEY, SRP_A (and SECRET_HASH).
    ///
    /// * DEVICE_PASSWORD_VERIFIER requires everything that PASSWORD_VERIFIER requires, plus DEVICE_KEY.
    ///
    /// * MFA_SETUP requires USERNAME, plus you must use the session value returned by VerifySoftwareToken in the Session parameter.
    ///
    ///
    /// For more information about SECRET_HASH, see [Computing secret hash values](https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash). For information about DEVICE_KEY, see [Working with user devices in your user pool](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-device-tracking.html).
    var challengeResponses: [String:String]?
    /// The app client ID.
    /// This member is required.
    var clientId: String?
    /// A map of custom key-value pairs that you can provide as input for any custom workflows that this action triggers. You create custom workflows by assigning Lambda functions to user pool triggers. When you use the RespondToAuthChallenge API action, Amazon Cognito invokes any functions that are assigned to the following triggers: post authentication, pre token generation, define auth challenge, create auth challenge, and verify auth challenge. When Amazon Cognito invokes any of these functions, it passes a JSON payload, which the function receives as input. This payload contains a clientMetadata attribute, which provides the data that you assigned to the ClientMetadata parameter in your RespondToAuthChallenge request. In your function code in Lambda, you can process the clientMetadata value to enhance your workflow for your specific needs. For more information, see [ Customizing user pool Workflows with Lambda Triggers](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools-working-with-aws-lambda-triggers.html) in the Amazon Cognito Developer Guide. When you use the ClientMetadata parameter, remember that Amazon Cognito won't do the following:
    ///
    /// * Store the ClientMetadata value. This data is available only to Lambda triggers that are assigned to a user pool to support custom workflows. If your user pool configuration doesn't include triggers, the ClientMetadata parameter serves no purpose.
    ///
    /// * Validate the ClientMetadata value.
    ///
    /// * Encrypt the ClientMetadata value. Don't use Amazon Cognito to provide sensitive information.
    var clientMetadata: [String:String]?
    /// The session that should be passed both ways in challenge-response calls to the service. If InitiateAuth or RespondToAuthChallenge API call determines that the caller must pass another challenge, they return a session with other challenge parameters. This session should be passed as it is to the next RespondToAuthChallenge API call.
    var session: String?
    /// Contextual data about your user session, such as the device fingerprint, IP address, or location. Amazon Cognito advanced security evaluates the risk of an authentication event based on the context that your app generates and passes to Amazon Cognito when it makes API requests.
    var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?

    enum CodingKeys: String, CodingKey {
        case analyticsMetadata = "AnalyticsMetadata"
        case challengeName = "ChallengeName"
        case challengeResponses = "ChallengeResponses"
        case clientId = "ClientId"
        case clientMetadata = "ClientMetadata"
        case session = "Session"
        case userContextData = "UserContextData"
    }
}


/// The response to respond to the authentication challenge.
struct RespondToAuthChallengeOutputResponse: Equatable, Decodable {
    /// The result returned by the server in response to the request to respond to the authentication challenge.
    var authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType?
    /// The challenge name. For more information, see [InitiateAuth](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html).
    var challengeName: CognitoIdentityProviderClientTypes.ChallengeNameType?
    /// The challenge parameters. For more information, see [InitiateAuth](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html).
    var challengeParameters: [String: String]?
    /// The session that should be passed both ways in challenge-response calls to the service. If the caller must pass another challenge, they return a session with other challenge parameters. This session should be passed as it is to the next RespondToAuthChallenge API call.
    var session: String?

    enum CodingKeys: String, CodingKey {
        case authenticationResult = "AuthenticationResult"
        case challengeName = "ChallengeName"
        case challengeParameters = "ChallengeParameters"
        case session = "Session"
    }

    init(from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        challengeName = try containerValues.decodeIfPresent(
            CognitoIdentityProviderClientTypes.ChallengeNameType.self, forKey: .challengeName
        )
        session = try containerValues.decodeIfPresent(String.self, forKey: .session)

        let challengeParameters = try containerValues.decodeIfPresent(
            [String: String?].self,
            forKey: .challengeParameters
        )?.reduce(into: [String: String](), { partialResult, pair in
            let (key, value) = pair
            if let value {
                partialResult[key] = value
            }
        })

        authenticationResult = try containerValues.decodeIfPresent(
            CognitoIdentityProviderClientTypes.AuthenticationResultType.self,
            forKey: .authenticationResult
        )
    }
}
