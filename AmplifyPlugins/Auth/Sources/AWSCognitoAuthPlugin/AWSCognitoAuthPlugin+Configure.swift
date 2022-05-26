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
                AuthPluginErrorConstants.decodeConfigurationError.recoverySuggestion)
        }

        let authConfiguration = try ConfigurationHelper.authConfiguration(jsonValueConfiguration)

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = makeAuthEnvironment(authConfiguration: authConfiguration)

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = credentialStoreEnvironment(authConfiguration: authConfiguration)

        let authStateMachine = StateMachine(resolver: authResolver, environment: authEnvironment)
        let credentialStoreMachine = StateMachine(resolver: credentialStoreResolver,
                                                  environment: credentialEnvironment)
        let hubEventHandler = AuthHubEventHandler()

        configure(authConfiguration: authConfiguration,
                  authStateMachine: authStateMachine,
                  credentialStoreStateMachine: credentialStoreMachine,
                  hubEventHandler: hubEventHandler)
    }

    func configure(authConfiguration: AuthConfiguration,
                   authStateMachine: AuthStateMachine,
                   credentialStoreStateMachine: CredentialStoreStateMachine,
                   hubEventHandler: AuthHubEventBehavior,
                   queue: OperationQueue = OperationQueue()) {

        self.authConfiguration = authConfiguration
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
        self.authStateMachine = authStateMachine
        self.authStateListenerToken = listenToAuthStateChange(authStateMachine)
        self.hubEventHandler = hubEventHandler

        self.credentialStoreStateMachine = credentialStoreStateMachine
        internalConfigure()
    }

    func listenToAuthStateChange(_ stateMachine: AuthStateMachine) ->
    AuthStateMachine.StateChangeListenerToken {

        return stateMachine.listen { state in
            self.log.verbose("""
            Auth state change:

            \(state)

            """)
        } onSubscribe: { }
    }

    func internalConfigure() {
        let request = AuthConfigureRequest(authConfiguration: authConfiguration)
        let operation = AuthConfigureOperation(
            request: request,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
        self.queue.addOperation(operation)
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

    func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior &
    AmplifyAuthCredentialStoreProvider {
        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration)
    }

    func makeLegacyCredentialStore(service: String) -> CredentialStoreBehavior {
        CredentialStore(service: service)
    }

    func makeAuthEnvironment(authConfiguration: AuthConfiguration) -> AuthEnvironment {

        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(
                userPoolConfigData: userPoolConfigurationData)

            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: nil,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: nil,
                logger: log)

        case .identityPools(let identityPoolConfigurationData):
            let authorizationEnvironment = authorizationEnvironment(
                identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: nil,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: nil,
                authorizationEnvironment: authorizationEnvironment,
                logger: log)

        case .userPoolsAndIdentityPools(let userPoolConfigurationData,
                                        let identityPoolConfigurationData):
            let authenticationEnvironment = authenticationEnvironment(
                userPoolConfigData: userPoolConfigurationData)
            let authorizationEnvironment = authorizationEnvironment(
                identityPoolConfigData: identityPoolConfigurationData)
            return AuthEnvironment(
                configuration: authConfiguration,
                userPoolConfigData: userPoolConfigurationData,
                identityPoolConfigData: identityPoolConfigurationData,
                authenticationEnvironment: authenticationEnvironment,
                authorizationEnvironment: authorizationEnvironment,
                logger: log)
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
