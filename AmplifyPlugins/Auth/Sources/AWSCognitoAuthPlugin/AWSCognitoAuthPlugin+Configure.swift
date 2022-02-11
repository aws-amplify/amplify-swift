//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

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

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = makeAuthEnvironment(authConfiguration: authConfiguration)

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = credentialStoreEnvironment(authConfiguration: authConfiguration)

        let authStateMachine = StateMachine(resolver: authResolver, environment: authEnvironment)
        let credentialStoreMachine = StateMachine(resolver: credentialStoreResolver, environment: credentialEnvironment)

        configure(authConfiguration: authConfiguration,
                  authStateMachine: authStateMachine,
                  credentialStoreStateMachine: credentialStoreMachine)
    }

    func configure(authConfiguration: AuthConfiguration,
                   authStateMachine: StateMachine<AuthState, AuthEnvironment>,
                   credentialStoreStateMachine: StateMachine<CredentialStoreState, CredentialEnvironment>,
                   queue: OperationQueue = OperationQueue()) {
        self.authConfiguration = authConfiguration
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        sendConfigureCredentialEvent()
    }

    func sendConfigureCredentialEvent() {
        var token: StateMachine<CredentialStoreState, CredentialEnvironment>.StateChangeListenerToken?
        token = credentialStoreStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            switch $0 {
            case .success(let storedCredentials):
                self.sendConfigureAuthEvent(with: storedCredentials)
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            case .error(let credentialStoreError):
                if case .itemNotFound = credentialStoreError {
                    self.sendConfigureAuthEvent(with: nil)
                } else {
                    let error = AuthError.service("An exception occurred when configuring credential store",
                                                  AmplifyErrorMessages.reportBugToAWS(),
                                                  credentialStoreError)
                    Amplify.log.error(error: error)
                }
                
                if let token = token {
                    self.credentialStoreStateMachine.cancel(listenerToken: token)
                }
            default:
                break
            }
        } onSubscribe: { [weak self] in
            self?.credentialStoreStateMachine.send(CredentialStoreEvent(eventType: .migrateLegacyCredentialStore))
        }
    }

    func sendConfigureAuthEvent(with storedCredentials: CognitoCredentials?) {
        authStateMachine.send(AuthEvent(eventType: .configureAuth(authConfiguration, storedCredentials)))
    }

    func authConfiguration(userPoolConfig: UserPoolConfigurationData?,
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

    func parseUserPoolConfigData(_ config: JSONValue) -> UserPoolConfigurationData? {
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

    func makeIdentityClient() throws -> CognitoIdentityBehavior {
        switch authConfiguration {
        case .identityPools(let identityPoolConfig), .userPoolsAndIdentityPools(_, let identityPoolConfig):
            let configuration = try CognitoIdentityClient.CognitoIdentityClientConfiguration(
                frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                region: identityPoolConfig.region)
            return CognitoIdentityClient(config: configuration)
        default:
            fatalError()
        }
    }

    func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior & AmplifyAuthCredentialStoreProvider {
        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration)
    }

    func makeLegacyCredentialStore(service: String) -> CredentialStoreBehavior {
        CredentialStore(service: service)
    }

    func makeAuthEnvironment(authConfiguration: AuthConfiguration) -> AuthEnvironment {
        
        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(userPoolConfigData: userPoolConfigurationData)
            
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: nil,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: nil)
            
        case .identityPools(let identityPoolConfigurationData):
            let authorizationEnvironment = authorizationEnvironment(identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: nil,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: nil,
                authorizationEnvironment: authorizationEnvironment)
            
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(userPoolConfigData: userPoolConfigurationData)
            let authorizationEnvironment = authorizationEnvironment(identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: authorizationEnvironment)
        }
    }

    func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(userPoolConfiguration: userPoolConfigData,
                                                           cognitoUserPoolFactory: makeUserPool)
        return BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment,
                                              userPoolEnvironment: userPoolEnvironment)
    }

    func authorizationEnvironment(identityPoolConfigData: IdentityPoolConfigurationData) -> AuthorizationEnvironment {
        BasicAuthorizationEnvironment(identityPoolConfiguration: identityPoolConfigData,
                                      cognitoIdentityFactory: makeIdentityClient)
    }

    func credentialStoreEnvironment(authConfiguration: AuthConfiguration) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: makeCredentialStore,
                legacyCredentialStoreFactory: makeLegacyCredentialStore(service:)
            )
        )
    }

}

extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {}

extension CognitoIdentityClient: CognitoIdentityBehavior {}
