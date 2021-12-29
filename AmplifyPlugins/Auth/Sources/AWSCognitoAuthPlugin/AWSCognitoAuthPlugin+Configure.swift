//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import hierarchical_state_machine_swift
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore

extension AWSCognitoAuthPlugin {

    /// Configures AWSCognitoAuthPlugin with the specified configuration.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {

        guard let jsonValueConfiguration = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                AuthPluginErrorConstants.decodeConfigurationError.errorDescription,
                AuthPluginErrorConstants.decodeConfigurationError.recoverySuggestion
            )
        }

        let userPoolConfigData = parseUserPoolConfigData(jsonValueConfiguration)
        let identityPoolConfigData = parseIdentityPoolConfigData(jsonValueConfiguration)
        let authConfiguration = try authConfiguration(userPoolConfig: userPoolConfigData,
                                                      identityPoolConfig: identityPoolConfigData)
        let environment = makeAuthEnvironment(authConfiguration: authConfiguration)

        let resolver = AuthState.Resolver().eraseToAnyResolver()
        let stateMachine = StateMachine(resolver: resolver, environment: environment)
        configure(authConfiguration: authConfiguration, stateMachine: stateMachine)

        stateMachine.send(AuthEvent(eventType: .configureAuth(authConfiguration)))
    }

    func configure(authConfiguration: AuthConfiguration,
                   stateMachine: StateMachine<AuthState, AuthEnvironment>,
                   queue: OperationQueue = OperationQueue())
    {
        self.authConfiguration = authConfiguration
        self.stateMachine = stateMachine
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
    }

    func authConfiguration(userPoolConfig: UserPoolConfigurationData?,
                           identityPoolConfig: IdentityPoolConfigurationData?) throws -> AuthConfiguration
    {

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

    func parseUserPoolConfigData(_ config: JSONValue) ->  UserPoolConfigurationData? {
        //TODO: Use JSON serialization here to convert.
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

        var clientSecret: String?
        if case .string(let clientSecretFromConfig) = cognitoUserPoolJSON.value(at: "AppClientSecret") {
            clientSecret = clientSecretFromConfig
        }
        return UserPoolConfigurationData(poolId: poolId,
                                         clientId: appClientId,
                                         region: region,
                                         clientSecret: clientSecret)
    }

    func parseIdentityPoolConfigData(_ config: JSONValue) -> IdentityPoolConfigurationData? {

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
    
    func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools(let userPoolConfig), .userPoolsAndIdentityPools(let userPoolConfig, _):
            let configuration = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration(
                frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                region: userPoolConfig.region)
            return CognitoIdentityProviderClient(config: configuration)
            
        default:
            fatalError()
        }
    }
    
    func makeIdentityClient() throws -> CognitoIdentityClient {
        switch authConfiguration {
        case .identityPools(let identityPoolConfig), .userPoolsAndIdentityPools(_ , let identityPoolConfig):
            let configuration = try CognitoIdentityClient.CognitoIdentityClientConfiguration(
                frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                region: identityPoolConfig.region)
            return CognitoIdentityClient(config: configuration)
        default:
            fatalError()
        }
    }

    func makeAuthEnvironment(authConfiguration: AuthConfiguration) -> AuthEnvironment {

        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(userPoolConfigData: userPoolConfigurationData)
            return AuthEnvironment(userPoolConfigData: userPoolConfigurationData,
                                   identityPoolConfigData: nil,
                                   authenticationEnvironment: authenticationEnvironment)

        case .identityPools(let identityPoolConfigurationData):
            return AuthEnvironment(userPoolConfigData: nil,
                                   identityPoolConfigData: identityPoolConfigurationData,
                                   authenticationEnvironment: nil)

        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(userPoolConfigData: userPoolConfigurationData)
            return AuthEnvironment(userPoolConfigData: userPoolConfigurationData,
                                   identityPoolConfigData: identityPoolConfigurationData,
                                   authenticationEnvironment: authenticationEnvironment)
        }
    }

    func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        return BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment)
    }
}

extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {}
