//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import SmithyHTTPAPI

package struct UserPoolConfigurationData: Equatable {

    package let poolId: String
    package let clientId: String
    package let region: String
    package let endpoint: CustomEndpoint?
    package let clientSecret: String?
    package let pinpointAppId: String?
    package let hostedUIConfig: HostedUIConfigurationData?
    package let authFlowType: EngineAuthFlowType
    package let passwordProtectionSettings: PasswordProtectionSettings?
    package let usernameAttributes: [UsernameAttribute]
    package let signUpAttributes: [SignUpAttributeType]
    package let verificationMechanisms: [VerificationMechanism]

    package init(
        poolId: String,
        clientId: String,
        region: String,
        endpoint: CustomEndpoint? = nil,
        clientSecret: String? = nil,
        pinpointAppId: String? = nil,
        authFlowType: EngineAuthFlowType = .userSRP,
        hostedUIConfig: HostedUIConfigurationData? = nil,
        passwordProtectionSettings: PasswordProtectionSettings? = nil,
        usernameAttributes: [UsernameAttribute] = [],
        signUpAttributes: [SignUpAttributeType] = [],
        verificationMechanisms: [VerificationMechanism] = []
    ) {
        self.poolId = poolId
        self.clientId = clientId
        self.region = region
        self.endpoint = endpoint
        self.clientSecret = clientSecret
        self.pinpointAppId = pinpointAppId
        self.hostedUIConfig = hostedUIConfig
        self.authFlowType = authFlowType
        self.passwordProtectionSettings = passwordProtectionSettings
        self.usernameAttributes = usernameAttributes
        self.signUpAttributes = signUpAttributes
        self.verificationMechanisms = verificationMechanisms
    }

    /// Amazon Cognito user pool: cognito-idp.<region>.amazonaws.com/<YOUR_USER_POOL_ID>,
    /// for example, cognito-idp.us-east-1.amazonaws.com/us-east-1_123456789.
    package func getIdentityProviderName() -> String {
        return "cognito-idp.\(region).amazonaws.com/\(poolId)"
    }

    package static func isNamespacingEqual(
        lhs: UserPoolConfigurationData?,
        rhs: UserPoolConfigurationData?
    ) -> Bool {
            return lhs?.poolId == rhs?.poolId
            && lhs?.clientId == rhs?.clientId
            && lhs?.region == rhs?.region
        }
}

extension UserPoolConfigurationData: Codable { }

extension UserPoolConfigurationData: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "poolId": poolId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "clientId": clientId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "region": region.redactedForLog(),
            "endpoint": endpoint ?? "N/A",
            "clientSecret": clientSecret.maskedForLog(interiorCount: 4),
            "pinpointAppId": pinpointAppId.maskedForLog(interiorCount: 4, retainingCount: 4),
            "hostedUI": hostedUIConfig?.debugDescription ?? "N/A",
            "passwordProtectionSettings": passwordProtectionSettings.debugDescription,
            "usernameAttributes": usernameAttributes.debugDescription,
            "signUpAttributes": signUpAttributes.debugDescription,
            "verificationMechanisms": verificationMechanisms.debugDescription
        ]
    }
}

extension UserPoolConfigurationData: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}

package extension UserPoolConfigurationData {
    struct CustomEndpoint: Equatable, Codable {
        package let validatedHost: String

        package init(validatedHost: String) {
            self.validatedHost = validatedHost
        }

        package var resolver: AWSEndpointResolving {
            AWSEndpointResolving(Endpoint(host: validatedHost))
        }
    }
}

package extension UserPoolConfigurationData.CustomEndpoint {
    init(endpoint: String, validator: (String) throws -> Endpoint) rethrows {
        let endpoint = try validator(endpoint)
        validatedHost = endpoint.host
    }
}

package extension UserPoolConfigurationData {

    /// settings used in the Authenticator
    struct PasswordProtectionSettings: Equatable, Codable {
        package let minLength: UInt
        package let characterPolicy: [PasswordCharacterPolicy]

        package init(
            minLength: UInt,
            characterPolicy: [PasswordCharacterPolicy]
        ) {
            self.minLength = minLength
            self.characterPolicy = characterPolicy
        }
    }

    enum PasswordCharacterPolicy: String, Codable {
        case lowercase = "REQUIRES_LOWERCASE"
        case uppercase = "REQUIRES_UPPERCASE"
        case numbers = "REQUIRES_NUMBERS"
        case symbols = "REQUIRES_SYMBOLS"
    }
}

package extension UserPoolConfigurationData {

    /// Supported username attributes used in the Authenticator.
    enum UsernameAttribute: String, Codable {
        case username = "USERNAME"
        case email = "EMAIL"
        case phoneNumber = "PHONE_NUMBER"
    }
}

package extension UserPoolConfigurationData {

    /// Supported sign up attributes used in the Authenticator.
    enum SignUpAttributeType: String, Codable {
        case address = "ADDRESS"
        case birthDate = "BIRTHDATE"
        case email = "EMAIL"
        case familyName = "FAMILY_NAME"
        case gender = "GENDER"
        case givenName = "GIVEN_NAME"
        case middleName = "MIDDLE_NAME"
        case name = "NAME"
        case nickname = "NICKNAME"
        case phoneNumber = "PHONE_NUMBER"
        case preferredUsername = "PREFERRED_USERNAME"
        case profile = "PROFILE"
        case website = "WEBSITE"
    }
}

package extension UserPoolConfigurationData {

    /// Supported verification mechanisms used in the Authenticator.
    enum VerificationMechanism: String, Codable {
        case email = "EMAIL"
        case phoneNumber = "PHONE_NUMBER"
    }
}

// Plain values.
extension UserPoolConfigurationData: Sendable { }

extension UserPoolConfigurationData.CustomEndpoint: Sendable { }

extension UserPoolConfigurationData.PasswordProtectionSettings: Sendable { }

extension UserPoolConfigurationData.PasswordCharacterPolicy: Sendable { }

extension UserPoolConfigurationData.UsernameAttribute: Sendable { }

extension UserPoolConfigurationData.SignUpAttributeType: Sendable { }

extension UserPoolConfigurationData.VerificationMechanism: Sendable { }
