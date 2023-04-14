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

import ClientRuntime

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

        jsonConfiguration = jsonValueConfiguration

        let authConfiguration = try ConfigurationHelper.authConfiguration(jsonValueConfiguration)

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = credentialStoreEnvironment(authConfiguration: authConfiguration)
        let credentialStoreMachine = StateMachine(resolver: credentialStoreResolver,
                                                  environment: credentialEnvironment)
        let credentialsClient = CredentialStoreOperationClient(
            credentialStoreStateMachine: credentialStoreMachine)

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = makeAuthEnvironment(
            authConfiguration: authConfiguration,
            credentialsClient: credentialsClient
        )

        let authStateMachine = StateMachine(resolver: authResolver, environment: authEnvironment)

        let hubEventHandler = AuthHubEventHandler()
        let analyticsHandler = try UserPoolAnalytics(
            authConfiguration.getUserPoolConfiguration(),
            credentialStoreEnvironment: credentialEnvironment.credentialStoreEnvironment)

        configure(authConfiguration: authConfiguration,
                  authEnvironment: authEnvironment,
                  authStateMachine: authStateMachine,
                  credentialStoreStateMachine: credentialStoreMachine,
                  hubEventHandler: hubEventHandler,
                  analyticsHandler: analyticsHandler)
    }

    func configure(authConfiguration: AuthConfiguration,
                   authEnvironment: AuthEnvironment,
                   authStateMachine: AuthStateMachine,
                   credentialStoreStateMachine: CredentialStoreStateMachine,
                   hubEventHandler: AuthHubEventBehavior,
                   analyticsHandler: UserPoolAnalyticsBehavior,
                   queue: OperationQueue = OperationQueue()) {

        self.authConfiguration = authConfiguration
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
        self.authEnvironment = authEnvironment
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        self.internalConfigure()
        self.listenToStateMachineChanges()
        self.hubEventHandler = hubEventHandler
        self.analyticsHandler = analyticsHandler
        self.taskQueue = TaskQueue()
    }

    // MARK: - Configure Helpers
    private func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools(let userPoolConfig), .userPoolsAndIdentityPools(let userPoolConfig, _):
            let configuration = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration(
                endpointResolver: userPoolConfig.endpoint?.resolver,
                frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                region: userPoolConfig.region
            )

            if var httpClientEngineProxy = httpClientEngineProxy {
                let sdkEngine = configuration.httpClientEngine
                httpClientEngineProxy.target = sdkEngine
                configuration.httpClientEngine = httpClientEngineProxy
            }

            return CognitoIdentityProviderClient(config: configuration)
        default:
            fatalError()
        }
    }

    private func makeIdentityClient() throws -> CognitoIdentityBehavior {
        switch authConfiguration {
        case .identityPools(let identityPoolConfig), .userPoolsAndIdentityPools(_, let identityPoolConfig):
            let configuration = try CognitoIdentityClient.CognitoIdentityClientConfiguration(
                frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
                region: identityPoolConfig.region
            )
            return CognitoIdentityClient(config: configuration)
        default:
            fatalError()
        }
    }

    private func makeHostedUISession() -> HostedUISessionBehavior {
        return HostedUIASWebAuthenticationSession()
    }

    private func makeURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    private func makeRandomString() -> RandomStringBehavior {
        return RandomStringGenerator()
    }

    private func makeCognitoASF() -> AdvancedSecurityBehavior {
        CognitoUserPoolASF()
    }

    private func makeUserPoolAnalytics() -> UserPoolAnalyticsBehavior {
        return analyticsHandler
    }

    private func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior {
        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration)
    }

    private func makeLegacyKeychainStore(service: String) -> KeychainStoreBehavior {
        KeychainStore(service: service)
    }

    private func makeAuthEnvironment(
        authConfiguration: AuthConfiguration,
        credentialsClient: CredentialStoreStateBehavior
    ) -> AuthEnvironment {

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
                credentialsClient: credentialsClient,
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
                credentialsClient: credentialsClient,
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
                credentialsClient: credentialsClient,
                logger: log)
        }
    }

    private func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeUserPool,
            cognitoUserPoolASFFactory: makeCognitoASF,
            cognitoUserPoolAnalyticsHandlerFactory: makeUserPoolAnalytics)
        let hostedUIEnvironment = hostedUIEnvironment(userPoolConfigData)
        return BasicAuthenticationEnvironment(srpSignInEnvironment: srpSignInEnvironment,
                                              userPoolEnvironment: userPoolEnvironment,
                                              hostedUIEnvironment: hostedUIEnvironment)
    }

    private func hostedUIEnvironment(_ configuration: UserPoolConfigurationData) -> HostedUIEnvironment? {
        guard let hostedUIConfig = configuration.hostedUIConfig else {
            return nil
        }
        return BasicHostedUIEnvironment(configuration: hostedUIConfig,
                                        hostedUISessionFactory: makeHostedUISession,
                                        urlSessionFactory: makeURLSession,
                                        randomStringFactory: makeRandomString)
    }

    private func authorizationEnvironment(identityPoolConfigData: IdentityPoolConfigurationData) -> AuthorizationEnvironment {
        BasicAuthorizationEnvironment(identityPoolConfiguration: identityPoolConfigData,
                                      cognitoIdentityFactory: makeIdentityClient)
    }

    private func credentialStoreEnvironment(authConfiguration: AuthConfiguration) -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: makeCredentialStore,
                legacyKeychainStoreFactory: makeLegacyKeychainStore(service:)
            ), logger: log
        )
    }

    private func internalConfigure() {
        let request = AuthConfigureRequest(authConfiguration: authConfiguration)
        let operation = AuthConfigureOperation(
            request: request,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
        self.queue.addOperation(operation)
    }
}

extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {}

extension CognitoIdentityClient: CognitoIdentityBehavior {}
