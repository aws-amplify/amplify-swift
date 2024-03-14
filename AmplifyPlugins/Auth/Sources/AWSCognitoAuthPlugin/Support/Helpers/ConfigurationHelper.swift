//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(AmplifyUnifiedConfiguration) import Amplify

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
        if case .boolean(let isMigrationEnabled) = cognitoUserPoolJSON.value(at: "MigrationEnabled"),
           isMigrationEnabled == true {
            authFlowType = .userPassword
        } else if let authJson = config.value(at: "Auth.Default"),
                  case .string(let authFlowTypeJSON) = authJson.value(at: "authenticationFlowType"),
                  authFlowTypeJSON == "CUSTOM_AUTH" {
            authFlowType = .customWithSRP
        } else {
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

        // parse `passwordProtectionSettings`
        let cognitoConfiguration = config.value(at: "Auth.Default")
        var passwordProtectionSettings: UserPoolConfigurationData.PasswordProtectionSettings?
        if case .object(let passwordSettings) = cognitoConfiguration?.value(at: "passwordProtectionSettings") {

            // parse `minLength`
            var minLength: UInt = 0
            if case .number(let value) = passwordSettings["passwordPolicyMinLength"] {
                minLength = UInt(value)
            } else if case .string(let value) = passwordSettings["passwordPolicyMinLength"],
                      let intValue = UInt(value) {
                minLength = intValue
            }

            // parse `characterPolicy`
            var characterPolicy: [UserPoolConfigurationData.PasswordCharacterPolicy] = []
            if case .array(let characters) = passwordSettings["passwordPolicyCharacters"] {
                characterPolicy = characters.compactMap { value in
                    guard case .string(let string) = value else {
                        return nil
                    }

                    return .init(rawValue: string)
                }
            }

            passwordProtectionSettings = UserPoolConfigurationData.PasswordProtectionSettings(
                minLength: minLength,
                characterPolicy: characterPolicy
            )
        }

        // parse `usernameAttributes`
        var usernameAttributes: [UserPoolConfigurationData.UsernameAttribute] = []
        if case .array(let attributes) = cognitoConfiguration?["usernameAttributes"] {
            usernameAttributes = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        // parse `signUpAttributes`
        var signUpAttributes: [UserPoolConfigurationData.SignUpAttributeType] = []
        if case .array(let attributes) = cognitoConfiguration?["signupAttributes"] {
            signUpAttributes = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        // parse `verificationMechanisms`
        var verificationMechanisms: [UserPoolConfigurationData.VerificationMechanism] = []
        if case .array(let attributes) = cognitoConfiguration?["verificationMechanisms"] {
            verificationMechanisms = attributes.compactMap { value in
                guard case .string(let string) = value else {
                    return nil
                }

                return .init(rawValue: string)
            }
        }

        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         endpoint: endpoint,
                                         clientSecret: clientSecret,
                                         pinpointAppId: pinpointId,
                                         authFlowType: authFlowType,
                                         hostedUIConfig: hostedUIConfig,
                                         passwordProtectionSettings: passwordProtectionSettings,
                                         usernameAttributes: usernameAttributes,
                                         signUpAttributes: signUpAttributes,
                                         verificationMechanisms: verificationMechanisms)
    }

    static func parseUserPoolData(_ config: AmplifyConfigurationV2.Auth) throws -> UserPoolConfigurationData? {
        let hostedUIConfig = parseHostedConfiguration(configuration: config)

        // parse `passwordProtectionSettings`
        var passwordProtectionSettings: UserPoolConfigurationData.PasswordProtectionSettings? = nil
        if let passwordPolicy = config.passwordPolicy {

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

            passwordProtectionSettings = UserPoolConfigurationData.PasswordProtectionSettings(
                minLength: passwordPolicy.minLength,
                characterPolicy: characterPolicy
            )
        }

        // parse `usernameAttributes`
        let usernameAttributes: [UserPoolConfigurationData.UsernameAttribute] = config
            .usernameAttributes
            .compactMap { .init(rawValue: $0) }

        // parse `signUpAttributes`
        let signUpAttributes: [UserPoolConfigurationData.SignUpAttributeType] = config
            .usernameAttributes // TODO: Should be `signUpAttributes`, missing from unified config
            .compactMap { .init(rawValue: $0) }


        // parse `verificationMechanisms`
        let verificationMechanisms: [UserPoolConfigurationData.VerificationMechanism] = config
            .userVerificationMechanisms
            .compactMap { .init(rawValue: $0) }

        return UserPoolConfigurationData(poolId: config.userPoolId,
                                         clientId: config.userPoolClientId,
                                         region: config.awsRegion,
                                         endpoint: nil, // TODO: Custom Endpoint support, options object perhaps?
                                         clientSecret: nil, // TODO: confirm this is not needed
                                         pinpointAppId: nil, // TODO: confirm this is not needed
                                         authFlowType: .userSRP, // TODO: may be missing `authenticationFlowType`
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

    static func parseHostedConfiguration(configuration: AmplifyConfigurationV2.Auth) -> HostedUIConfigurationData? {

        guard let domain = configuration.oauthDomain,
              let signInRedirectURI = configuration.oauthRedirectSignIn,
              let signOutRedirectURI = configuration.oauthRedirectSignOut else {
            return nil
        }

        return createHostedConfiguration(appClientId: "TODO", // TODO: Missing Auth.Default.OAuth.AppClientId
                                         clientSecret: nil, // TODO: Auth.Default.OAuth.AppClientSecret no longer needed?
                                         domain: domain,
                                         scopes: configuration.oauthScopes,
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

    static func parseIdentityPoolData(_ config: AmplifyConfigurationV2.Auth) -> IdentityPoolConfigurationData? {
        IdentityPoolConfigurationData(poolId: config.identityPoolId,
                                      region: config.awsRegion) // TODO: IdentityPool used to have its own region, now it is shared.
    }

    static func authConfiguration(_ config: JSONValue) throws -> AuthConfiguration {
        let userPoolConfig = try parseUserPoolData(config)
        let identityPoolConfig = parseIdentityPoolData(config)

        return try createAuthConfiguration(userPoolConfig: userPoolConfig,
                                           identityPoolConfig: identityPoolConfig)
    }

    static func authConfiguration(_ config: AmplifyConfigurationV2) throws -> AuthConfiguration {
        guard let config = config.auth else {
            throw AuthError.configuration(
                "Error configuring \(String(describing: self))",
                AuthPluginErrorConstants.configurationMissingError
            )
        }
        let userPoolConfig = try parseUserPoolData(config)
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
}
