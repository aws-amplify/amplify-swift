//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct ConfigurationHelper {

    static func parseUserPoolData(_ config: JSONValue) -> UserPoolConfigurationData? {
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
        
        let endpoint: String? = {
            if case .string(let endpoint) = cognitoUserPoolJSON.value(at: "Endpoint") {
                return endpoint
            }
            return nil
        }()

        var authFlowType = AuthFlowType.unknown
        if case .boolean(let isMigrationEnabled) = cognitoUserPoolJSON.value(at: "MigrationEnabled"),
           isMigrationEnabled == true {
            authFlowType = .userPassword
        } else if let authJson = config.value(at: "Auth.Default"),
                   case .string(let authFlowTypeJSON) = authJson.value(at: "authenticationFlowType") {

            switch authFlowTypeJSON {
            case "CUSTOM_AUTH": authFlowType = .custom
            case "USER_SRP_AUTH": authFlowType = .userSRP
            default: authFlowType = .unknown
            }
        }

        var clientSecret: String?
        if case .string(let clientSecretFromConfig) = cognitoUserPoolJSON.value(at: "AppClientSecret") {
            clientSecret = clientSecretFromConfig
        }

        let hostedUIConfig = parseHostedConfiguration(
            configuration: config.value(at: "Auth.Default.OAuth"))

        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         endpoint: endpoint,
                                         clientSecret: clientSecret,
                                         authFlowType: authFlowType,
                                         hostedUIConfig: hostedUIConfig)
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
        let oauth = OAuthConfigurationData(domain: domain,
                                           scopes: scopesArray,
                                           signInRedirectURI: signInRedirectURI,
                                           signOutRedirectURI: signOutRedirectURI)
        return HostedUIConfigurationData(clientId: appClientId, oauth: oauth, clientSecret: nil)
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

    static func authConfiguration(_ config: JSONValue) throws -> AuthConfiguration {
        let userPoolConfig = parseUserPoolData(config)
        let identityPoolConfig = parseIdentityPoolData(config)

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
