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
                  authEnvironment: authEnvironment,
                  authStateMachine: authStateMachine,
                  credentialStoreStateMachine: credentialStoreMachine,
                  hubEventHandler: hubEventHandler)
    }

    func configure(authConfiguration: AuthConfiguration,
                   authEnvironment: AuthEnvironment,
                   authStateMachine: AuthStateMachine,
                   credentialStoreStateMachine: CredentialStoreStateMachine,
                   hubEventHandler: AuthHubEventBehavior,
                   queue: OperationQueue = OperationQueue()) {

        self.authConfiguration = authConfiguration
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
        self.authEnvironment = authEnvironment
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        self.setupStateMachine()
        self.hubEventHandler = hubEventHandler
    }

    // MARK: - Configure Helpers
    private func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools(let userPoolConfig), .userPoolsAndIdentityPools(let userPoolConfig, _):

            let configuration: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration
            if let customEndpoint = userPoolConfig.endpoint {
                configuration = try .init(
                    region: userPoolConfig.region,
                    endpointResolver: customEndpoint.resolver,
                    frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData()
                )
            } else {
                configuration = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration(
                    region: userPoolConfig.region, frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData())
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
                region: identityPoolConfig.region, frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData())
            return CognitoIdentityClient(config: configuration)
        default:
            fatalError()
        }
    }

    private func makeHostedUISession() -> HostedUISessionBehavior {
        return HostedUIASWebAuthenticationSession()
    }

    private func makeURLSession() -> URLSession {
        return URLSession.shared
    }

    private func makeRamdonString() -> RandomStringBehavior {
        return RandomStringGenerator()
    }


    private func makeCredentialStore() -> AmplifyAuthCredentialStoreBehavior {
        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration)
    }

    private func makeLegacyCredentialStore(service: String) -> CredentialStoreBehavior {
        CredentialStore(service: service)
    }

    private func makeAuthEnvironment(authConfiguration: AuthConfiguration) -> AuthEnvironment {

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

    private func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(userPoolConfiguration: userPoolConfigData,
                                                         cognitoUserPoolFactory: makeUserPool)
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(userPoolConfiguration: userPoolConfigData,
                                                           cognitoUserPoolFactory: makeUserPool)
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
                                        randomStringFactory: makeRamdonString)
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
                legacyCredentialStoreFactory: makeLegacyCredentialStore(service:)
            )
        )
    }

    /// If a custom endpoint is present, call this method to confirm proper formatting
    /// and resolve the `userPoolConfiguration` to a `ClientRuntime.Endpoint`.
    ///
    /// With a `ClientRuntime.Endpoint`, you can create a `AWSEndpointResolving`,
    /// to pass as the `endpointResolver` to
    /// `CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration`.
    ///
    ///       if let customEndpoint = userPoolConfig.endpoint {
    ///         let resolvedEndpoint = try makeUserPoolEndpoint(from: customEndpoint)
    ///         let endpointResolver = AWSEndpointResolving(resolvedEndpoint)
    ///         configuration = try .init(
    ///             region: ...,
    ///             endpointResolver: endpointResolver,
    ///             frameworkMetadata: ...
    ///         )
    ///       }
    ///
    /// - Parameter endpoint: The value from the `endpoint` key of the `amplifyconfiguration.json` file
    /// - Returns: A `ClientRuntime.Endpoint` used to instantiate a `EndpointResolving`.
    private func makeUserPoolEndpoint(
        from endpoint: String
    ) throws -> ClientRuntime.Endpoint {
        let endpoint = try EndpointResolving.userPool.run(endpoint)
        return endpoint
    }
}

extension CognitoIdentityProviderClient: CognitoUserPoolBehavior {}

extension CognitoIdentityClient: CognitoIdentityBehavior {}


