//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
@_spi(InternalAmplifyConfiguration) import Amplify
import SmithyHTTPAPI

struct UserPoolConfigurationData: Equatable {

    let poolId: String
    let clientId: String
    let region: String
    let endpoint: CustomEndpoint?
    let clientSecret: String?
    let pinpointAppId: String?
    let hostedUIConfig: HostedUIConfigurationData?
    let authFlowType: AuthFlowType
    let passwordProtectionSettings: PasswordProtectionSettings?
    let usernameAttributes: [UsernameAttribute]
    let signUpAttributes: [SignUpAttributeType]
    let verificationMechanisms: [VerificationMechanism]

    init(
        poolId: String,
        clientId: String,
        region: String,
        endpoint: CustomEndpoint? = nil,
        clientSecret: String? = nil,
        pinpointAppId: String? = nil,
        authFlowType: AuthFlowType = .userSRP,
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
    func getIdentityProviderName() -> String {
        return "cognito-idp.\(region).amazonaws.com/\(poolId)"
    }
}

extension UserPoolConfigurationData: Codable { }

extension UserPoolConfigurationData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "poolId": poolId.masked(interiorCount: 4, retainingCount: 4),
            "clientId": clientId.masked(interiorCount: 4, retainingCount: 4),
            "region": region.redacted(),
            "endpoint": endpoint ?? "N/A",
            "clientSecret": clientSecret.masked(interiorCount: 4),
            "pinpointAppId": pinpointAppId.masked(interiorCount: 4, retainingCount: 4),
            "hostedUI": hostedUIConfig?.debugDescription ?? "N/A",
            "passwordProtectionSettings": passwordProtectionSettings.debugDescription,
            "usernameAttributes": usernameAttributes.debugDescription,
            "signUpAttributes": signUpAttributes.debugDescription,
            "verificationMechanisms": verificationMechanisms.debugDescription
        ]
    }
}

extension UserPoolConfigurationData: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}

extension UserPoolConfigurationData {
    struct CustomEndpoint: Equatable, Codable {
        let validatedHost: String

        var resolver: AWSEndpointResolving {
            AWSEndpointResolving(Endpoint(host: validatedHost))
        }
    }
}

extension UserPoolConfigurationData.CustomEndpoint {
    init(endpoint: String, validator: (String) throws -> Endpoint) rethrows {
        let endpoint = try validator(endpoint)
        validatedHost = endpoint.host
    }
}

extension UserPoolConfigurationData {

    /// settings used in the Authenticator
    struct PasswordProtectionSettings: Equatable, Codable {
        let minLength: UInt
        let characterPolicy: [PasswordCharacterPolicy]

        init(from passwordPolicy: AmplifyOutputsData.Auth.PasswordPolicy) {
            var characterPolicy = [UserPoolConfigurationData.PasswordCharacterPolicy]()
            if passwordPolicy.requireLowercase {
                characterPolicy.append(.lowercase)
            }
            if passwordPolicy.requireUppercase {
                characterPolicy.append(.uppercase)
            }
            if passwordPolicy.requireNumbers {
                characterPolicy.append(.numbers)
            }
            if passwordPolicy.requireSymbols {
                characterPolicy.append(.symbols)
            }

            self.minLength = passwordPolicy.minLength
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

extension UserPoolConfigurationData {

    /// Supported username attributes used in the Authenticator.
    enum UsernameAttribute: String, Codable {
        case username = "USERNAME"
        case email = "EMAIL"
        case phoneNumber = "PHONE_NUMBER"

        init(from attribute: AmplifyOutputsData.Auth.UsernameAttributes) {
            switch attribute {
            case .email:
                self = .email
            case .phoneNumber:
                self = .phoneNumber
            }
        }
    }
}

extension UserPoolConfigurationData {

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

        init?(from attribute: AmplifyOutputsData.AmazonCognitoStandardAttributes) {
            switch attribute {
            case .address:
                self = .address
            case .birthdate:
                self = .birthDate
            case .email:
                self = .email
            case .familyName:
                self = .familyName
            case .gender:
                self = .gender
            case .givenName:
                self = .givenName
            case .locale:
                return nil
            case .middleName:
                self = .middleName
            case .name:
                self = .name
            case .nickname:
                self = .nickname
            case .phoneNumber:
                self = .phoneNumber
            case .picture:
                return nil
            case .preferredUsername:
                self = .preferredUsername
            case .profile:
                self = .profile
            case .sub:
                return nil
            case .updatedAt:
                return nil
            case .website:
                self = .website
            case .zoneinfo:
                return nil
            }
        }
    }
}

extension UserPoolConfigurationData {

    /// Supported verification mechanisms used in the Authenticator.
    enum VerificationMechanism: String, Codable {
        case email = "EMAIL"
        case phoneNumber = "PHONE_NUMBER"

        init(from attribute: AmplifyOutputsData.Auth.UserVerificationType) {
            switch attribute {
            case .email:
                self = .email
            case .phoneNumber:
                self = .phoneNumber
            }
        }
    }
}
