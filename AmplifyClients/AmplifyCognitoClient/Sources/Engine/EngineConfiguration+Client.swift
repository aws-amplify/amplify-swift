//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// The engine's `AuthConfiguration`, built from the client's. A 1:1 map of
// `EngineConfigurationInput`, which already made every `ConfigurationHelper` decision: the hosted
// UI's first redirect URIs and `nil` secret, the character-policy order, the sign-up attribute filter, and the
// `.userSRP`, `nil` endpoint and `nil` Pinpoint constants. Nothing here decides anything; every enum is mapped
// case to case, never through a raw value.

extension AuthConfiguration {

    init(client configuration: AuthClientConfiguration) {
        self.init(configuration.engineInput)
    }

    init(_ input: EngineConfigurationInput) {
        switch input {
        case .userPools(let userPool):
            self = .userPools(UserPoolConfigurationData(userPool))
        case .identityPools(let identityPool):
            self = .identityPools(IdentityPoolConfigurationData(identityPool))
        case .userPoolsAndIdentityPools(let userPool, let identityPool):
            self = .userPoolsAndIdentityPools(UserPoolConfigurationData(userPool), IdentityPoolConfigurationData(identityPool))
        }
    }
}

extension IdentityPoolConfigurationData {

    init(_ settings: EngineIdentityPoolSettings) {
        self.init(poolId: settings.poolId, region: settings.region)
    }
}

extension UserPoolConfigurationData {

    init(_ settings: EngineUserPoolSettings) {
        self.init(
            poolId: settings.poolId,
            clientId: settings.clientId,
            region: settings.region,
            // `amplify_outputs` has no custom endpoint, so `settings.endpoint` is always `nil`.
            endpoint: settings.endpoint.map { UserPoolConfigurationData.CustomEndpoint(validatedHost: $0) },
            clientSecret: settings.clientSecret,
            pinpointAppId: settings.pinpointAppId,
            authFlowType: EngineAuthFlowType(settings.authFlowType),
            hostedUIConfig: settings.hostedUIConfig.map(HostedUIConfigurationData.init),
            passwordProtectionSettings: settings.passwordProtectionSettings.map(PasswordProtectionSettings.init),
            usernameAttributes: settings.usernameAttributes.map(UsernameAttribute.init),
            signUpAttributes: settings.signUpAttributes.compactMap(SignUpAttributeType.init),
            verificationMechanisms: settings.verificationMechanisms.map(VerificationMechanism.init)
        )
    }
}

extension EngineAuthFlowType {

    init(_ flow: EngineUserPoolSettings.AuthFlowType) {
        switch flow {
        case .userSRP:
            self = .userSRP
        }
    }
}

extension HostedUIConfigurationData {

    init(_ settings: EngineUserPoolSettings.HostedUIConfig) {
        self.init(
            clientId: settings.clientId,
            oauth: OAuthConfigurationData(
                domain: settings.oauth.domain,
                scopes: settings.oauth.scopes,
                signInRedirectURI: settings.oauth.signInRedirectURI,
                signOutRedirectURI: settings.oauth.signOutRedirectURI
            ),
            clientSecret: settings.clientSecret
        )
    }
}

extension UserPoolConfigurationData.PasswordProtectionSettings {

    init(_ settings: EngineUserPoolSettings.PasswordProtectionSettings) {
        self.init(
            minLength: settings.minLength,
            characterPolicy: settings.characterPolicy.map(UserPoolConfigurationData.PasswordCharacterPolicy.init)
        )
    }
}

extension UserPoolConfigurationData.PasswordCharacterPolicy {

    init(_ policy: EngineUserPoolSettings.PasswordCharacterPolicy) {
        switch policy {
        case .lowercase: self = .lowercase
        case .uppercase: self = .uppercase
        case .numbers: self = .numbers
        case .symbols: self = .symbols
        }
    }
}

extension UserPoolConfigurationData.UsernameAttribute {

    init(_ attribute: AuthClientConfiguration.UsernameAttribute) {
        switch attribute {
        case .email: self = .email
        case .phoneNumber: self = .phoneNumber
        }
    }
}

extension UserPoolConfigurationData.VerificationMechanism {

    init(_ mechanism: AuthClientConfiguration.VerificationMechanism) {
        switch mechanism {
        case .email: self = .email
        case .phoneNumber: self = .phoneNumber
        }
    }
}

extension UserPoolConfigurationData.SignUpAttributeType {

    /// The engine's case for a standard attribute, or `nil` for the ones it has none for.
    /// `EngineUserPoolSettings.signUpAttributes` holds only the 13 it has (`signUpAttributeKeys`), so `nil` is
    /// unreachable from a configuration; it keeps the switch exhaustive without a `default:`.
    init?(_ key: AuthClientUserAttributeKey) {
        switch key {
        case .address: self = .address
        case .birthDate: self = .birthDate
        case .email: self = .email
        case .familyName: self = .familyName
        case .gender: self = .gender
        case .givenName: self = .givenName
        case .middleName: self = .middleName
        case .name: self = .name
        case .nickname: self = .nickname
        case .phoneNumber: self = .phoneNumber
        case .preferredUsername: self = .preferredUsername
        case .profile: self = .profile
        case .website: self = .website
        case .emailVerified, .locale, .phoneNumberVerified, .picture, .sub, .updatedAt, .zoneInfo, .custom, .unknown:
            return nil
        }
    }
}

extension PoolNamespace {

    /// The pools of an engine configuration, whose session account is `amplify.<keyComponent>.session`.
    init(_ configuration: AuthConfiguration) {
        switch configuration {
        case .userPools(let userPool):
            self = .userPool(userPool.poolId)
        case .identityPools(let identityPool):
            self = .identityPool(identityPool.poolId)
        case .userPoolsAndIdentityPools(let userPool, let identityPool):
            self = .userPoolAndIdentityPool(userPoolId: userPool.poolId, identityPoolId: identityPool.poolId)
        }
    }
}
