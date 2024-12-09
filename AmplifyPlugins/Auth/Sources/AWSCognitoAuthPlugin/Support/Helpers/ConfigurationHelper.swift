//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) import Amplify

struct ConfigurationHelper {

    static func parseUserPoolData(_ config: JSONValue) throws -> UserPoolConfigurationData? {
        // TODO: Use JSON serialization here to convert.
        guard let cognitoUserPoolJSON = config.value(at: "CognitoUserPool.Default") else {
            Amplify.Logging.info("Could not find Cognito User Pool configuration")
            return nil
        }
        guard case .string(let poolId)  = cognitoUserPoolJSON.value(at: "PoolId"),
              case .string(let appClientId) = cognitoUserPoolJSON.value(at: "AppClientId"),
              case .string(let region) = cognitoUserPoolJSON.value(at: "Region")
        else {
            return nil
        }

        // parse `pinpointId`
        var pinpointId: String?
        if case .string(let pinpointIdFromConfig) = cognitoUserPoolJSON.value(at: "PinpointAppId") {
            pinpointId = pinpointIdFromConfig
        }

        // If there's a value for the key `Endpoint` let's validate
        // that input here. This allows us to validate once instead
        // of repeatedly whenever `AWSCongnitoAuthPlugin().makeUserPool()`
        // is called. It also allows us to throw an appropriate error
        // at configuration time to reduce the "distance" between invalid
        // input and error handling.
        let endpoint: UserPoolConfigurationData.CustomEndpoint? = try {
            if case .string(let endpoint) = cognitoUserPoolJSON.value(at: "Endpoint") {
                return try .init(
                    endpoint: endpoint,
                    validator: EndpointResolving.userPool.run
                )
            }
            return nil
        }()

        // parse `authFlowType`
        var authFlowType: AuthFlowType

        // If Migration path is enabled, auth flow type should always be set to USER_PASSWORD_AUTH
        if case .boolean(let isMigrationEnabled) = cognitoUserPoolJSON.value(at: "MigrationEnabled"),
           isMigrationEnabled == true {
            authFlowType = .userPassword
        } else if let authJson = config.value(at: "Auth.Default"),
                  case .string(let authFlowTypeConfigValue) = authJson.value(at: "authenticationFlowType"),
                  let authFlowTypeFromConfig = AuthFlowType(rawValue: authFlowTypeConfigValue) {
            authFlowType = authFlowTypeFromConfig
        } else {
            // if the auth flow type is not found from config, default to SRP
            authFlowType = .userSRP
        }

        // parse `clientSecret`
        var clientSecret: String?
        if case .string(let clientSecretFromConfig) = cognitoUserPoolJSON.value(at: "AppClientSecret") {
            clientSecret = clientSecretFromConfig
        }

        // parse `hostedUIConfig`
        let hostedUIConfig = parseHostedConfiguration(
            configuration: config.value(at: "Auth.Default.OAuth"))

        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         endpoint: endpoint,
                                         clientSecret: clientSecret,
                                         pinpointAppId: pinpointId,
                                         authFlowType: authFlowType,
                                         hostedUIConfig: hostedUIConfig,
                                         passwordProtectionSettings: nil,
                                         usernameAttributes: [],
                                         signUpAttributes: [],
                                         verificationMechanisms: [])
    }

    static func parseUserPoolData(_ config: AmplifyOutputsData.Auth) -> UserPoolConfigurationData? {
        let hostedUIConfig = parseHostedConfiguration(configuration: config)

        // parse `passwordProtectionSettings`
        var passwordProtectionSettings: UserPoolConfigurationData.PasswordProtectionSettings? = nil
        if let passwordPolicy = config.passwordPolicy {
            passwordProtectionSettings = .init(from: passwordPolicy)
        }

        // parse `usernameAttributes`
        let usernameAttributes: [UserPoolConfigurationData.UsernameAttribute] = config
            .usernameAttributes?
            .compactMap { .init(from: $0) } ?? []

        // parse `signUpAttributes`
        let signUpAttributes: [UserPoolConfigurationData.SignUpAttributeType] = config
            .standardRequiredAttributes?
            .compactMap { .init(from: $0) } ?? []

        // parse `verificationMechanisms`
        let verificationMechanisms: [UserPoolConfigurationData.VerificationMechanism] = config
            .userVerificationTypes?
            .compactMap { .init(from: $0) } ?? []

        return UserPoolConfigurationData(poolId: config.userPoolId,
                                         clientId: config.userPoolClientId,
                                         region: config.awsRegion,
                                         endpoint: nil, // Gen2 does not support this field
                                         clientSecret: nil, // Gen2 does not support this field
                                         pinpointAppId: nil, // Gen2 does not support this field
                                         authFlowType: .userSRP,
                                         hostedUIConfig: hostedUIConfig,
                                         passwordProtectionSettings: passwordProtectionSettings,
                                         usernameAttributes: usernameAttributes,
                                         signUpAttributes: signUpAttributes,
                                         verificationMechanisms: verificationMechanisms)
    }

    static func parseHostedConfiguration(configuration: JSONValue?) -> HostedUIConfigurationData? {

        guard case .string(let domain)  = configuration?.value(at: "WebDomain"),
              case .array(let scopes) = configuration?.value(at: "Scopes"),
              case .string(let appClientId) = configuration?.value(at: "AppClientId"),
              case .string(let signInRedirectURI) = configuration?.value(at: "SignInRedirectURI"),
              case .string(let signOutRedirectURI) = configuration?.value(at: "SignOutRedirectURI")
        else {
            return nil
        }
        let scopesArray = scopes.map { value -> String in
            if case .string(let scope) = value {
                return scope
            }
            return ""
        }

        var clientSecret: String?
        if case .string(let appClientSecret) = configuration?.value(at: "AppClientSecret") {
            clientSecret = appClientSecret
        }

        return createHostedConfiguration(appClientId: appClientId,
                                         clientSecret: clientSecret,
                                         domain: domain,
                                         scopes: scopesArray,
                                         signInRedirectURI: signInRedirectURI,
                                         signOutRedirectURI: signOutRedirectURI)
    }

    static func parseHostedConfiguration(configuration: AmplifyOutputsData.Auth) -> HostedUIConfigurationData? {
        guard let oauth = configuration.oauth,
              let signInRedirectURI = oauth.redirectSignInUri.first,
              let signOutRedirectURI = oauth.redirectSignOutUri.first else {
            return nil
        }

        return createHostedConfiguration(appClientId: configuration.userPoolClientId,
                                         clientSecret: nil,
                                         domain: oauth.domain,
                                         scopes: oauth.scopes,
                                         signInRedirectURI: signInRedirectURI,
                                         signOutRedirectURI: signOutRedirectURI)

    }
    static func createHostedConfiguration(appClientId: String,
                                          clientSecret: String?,
                                          domain: String,
                                          scopes: [String],
                                          signInRedirectURI: String,
                                          signOutRedirectURI: String) -> HostedUIConfigurationData {

        let oauth = OAuthConfigurationData(domain: domain,
                                           scopes: scopes,
                                           signInRedirectURI: signInRedirectURI,
                                           signOutRedirectURI: signOutRedirectURI)

        return HostedUIConfigurationData(clientId: appClientId,
                                         oauth: oauth,
                                         clientSecret: clientSecret)
    }

    static func parseIdentityPoolData(_ config: JSONValue) -> IdentityPoolConfigurationData? {

        guard let cognitoIdentityPoolJSON = config.value(at: "CredentialsProvider.CognitoIdentity.Default") else {
            Amplify.Logging.info("Could not find Cognito Identity Pool configuration")
            return nil
        }
        guard case .string(let poolId) = cognitoIdentityPoolJSON.value(at: "PoolId"),
              case .string(let region) = cognitoIdentityPoolJSON.value(at: "Region")
        else {
            return nil
        }
        return IdentityPoolConfigurationData(poolId: poolId, region: region)
    }

    static func parseIdentityPoolData(_ config: AmplifyOutputsData.Auth) -> IdentityPoolConfigurationData? {
        if let identityPoolId = config.identityPoolId {
            return IdentityPoolConfigurationData(poolId: identityPoolId,
                                                 region: config.awsRegion)
        } else {
            return nil
        }
    }

    static func authConfiguration(_ config: JSONValue) throws -> AuthConfiguration {
        let userPoolConfig = try parseUserPoolData(config)
        let identityPoolConfig = parseIdentityPoolData(config)

        return try createAuthConfiguration(userPoolConfig: userPoolConfig,
                                           identityPoolConfig: identityPoolConfig)
    }

    static func authConfiguration(_ config: AmplifyOutputsData) throws -> AuthConfiguration {
        guard let config = config.auth else {
            throw AuthError.configuration(
                "Error configuring \(String(describing: self))",
                AuthPluginErrorConstants.configurationMissingError
            )
        }
        let userPoolConfig = parseUserPoolData(config)
        let identityPoolConfig = parseIdentityPoolData(config)

        return try createAuthConfiguration(userPoolConfig: userPoolConfig,
                                           identityPoolConfig: identityPoolConfig)

    }

    static func createAuthConfiguration(userPoolConfig: UserPoolConfigurationData?,
                                        identityPoolConfig: IdentityPoolConfigurationData?) throws -> AuthConfiguration {
        if let userPoolConfigNonNil = userPoolConfig, let identityPoolConfigNonNil = identityPoolConfig {
            return .userPoolsAndIdentityPools(userPoolConfigNonNil, identityPoolConfigNonNil)
        }
        if  let userPoolConfigNonNil = userPoolConfig {
            return .userPools(userPoolConfigNonNil)
        }
        if  let identityPoolConfigNonNil = identityPoolConfig {
            return .identityPools(identityPoolConfigNonNil)
        }
        // Could not get either Userpool or Identitypool configuration
        // Throw an error to stop the configure flow.
        throw AuthError.configuration(
            "Error configuring \(String(describing: self))",
            AuthPluginErrorConstants.configurationMissingError
        )
    }

    static func createUserPoolJsonConfiguration(_ authConfig: AuthConfiguration) -> JSONValue {
        let config: UserPoolConfigurationData
        switch authConfig {
        case .userPools(let userPoolConfig):
            config = userPoolConfig
        case .userPoolsAndIdentityPools(let userPoolConfig, _):
            config = userPoolConfig
        case .identityPools:
            return JSONValue.null
        }

        let usernameAttributes: [JSONValue] = config.usernameAttributes.map { .string($0.rawValue) }
        let signUpAttributes: [JSONValue] = config.signUpAttributes.map { .string($0.rawValue) }
        let verificationMechanisms: [JSONValue] = config.verificationMechanisms.map { .string($0.rawValue) }

        let authConfigObject: JSONValue
        if let passwordProtectionSettings = config.passwordProtectionSettings {
            let minLength = Double(passwordProtectionSettings.minLength)
            let characterPolicy: [JSONValue] = passwordProtectionSettings.characterPolicy.map { .string($0.rawValue) }

            authConfigObject = .object(
                ["usernameAttributes": .array(usernameAttributes),
                 "signupAttributes": .array(signUpAttributes),
                 "verificationMechanism": .array(verificationMechanisms),
                 "passwordProtectionSettings": .object(
                    ["passwordPolicyMinLength": .number(Double(minLength)),
                     "passwordPolicyCharacters": .array(characterPolicy)])])
        } else {
            authConfigObject = .object(
                ["usernameAttributes": .array(usernameAttributes),
                 "signupAttributes": .array(signUpAttributes),
                 "verificationMechanism": .array(verificationMechanisms)])
        }

        return JSONValue.object([
            "Auth": .object([
                "Default": authConfigObject
            ])
        ])
    }
}
