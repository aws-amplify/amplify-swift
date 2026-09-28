//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
@_spi(InternalHttpEngineProxy) import AWSPluginsCore
import SmithyRetries
import SmithyRetriesAPI
import InternalAmplifyKeychain
import InternalAWSCognitoAuth

extension AWSCognitoAuthPlugin {

    /// Configures AWSCognitoAuthPlugin with the specified configuration.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {
        let authConfiguration: AuthConfiguration
        if let configuration = configuration as? AmplifyOutputsData {
            authConfiguration = try ConfigurationHelper.authConfiguration(configuration)
            jsonConfiguration = ConfigurationHelper.createUserPoolJsonConfiguration(authConfiguration)
        } else if let jsonValueConfiguration = configuration as? JSONValue {
            jsonConfiguration = jsonValueConfiguration
            authConfiguration = try ConfigurationHelper.authConfiguration(jsonValueConfiguration)
        } else {
            throw PluginError.pluginConfigurationError(
                AuthPluginErrorConstants.decodeConfigurationError.errorDescription,
                AuthPluginErrorConstants.decodeConfigurationError.recoverySuggestion
            )
        }

        // The environments outlive this call and the plugin owns them, so no factory may hold the plugin
        // strongly: the closures below capture it weakly, and the factories that read only values fixed
        // at this point capture those values instead (the preference types are not `Sendable`).
        let accessGroup = secureStoragePreferences?.accessGroup?.name
        let migrateKeychainItems = secureStoragePreferences?.accessGroup?.migrateKeychainItems ?? false
        let requestTimeout = networkPreferences?.timeoutIntervalForRequest
        let resourceTimeout = networkPreferences?.timeoutIntervalForResource
        let environmentFactory = AuthEnvironmentFactory(
            authConfiguration: authConfiguration,
            makeUserPool: { [weak self] in
                guard let self else { throw Self.releasedPluginError() }
                return try makeUserPool()
            },
            makeIdentityClient: { [weak self] in
                guard let self else { throw Self.releasedPluginError() }
                return try makeIdentityClient()
            },
            credentialStoreFactory: {
                Self.makeCredentialStore(
                    authConfiguration: authConfiguration,
                    accessGroup: accessGroup,
                    migrateKeychainItems: migrateKeychainItems
                )
            },
            legacyKeychainStoreFactory: Self.makeLegacyKeychainStore(service:),
            logger: AmplifyEngineLogRouter(),
            userPoolAnalytics: { [weak self] in
                self?.makeUserPoolAnalytics() ?? NoUserPoolAnalytics()
            },
            makeURLSession: {
                Self.makeURLSession(timeoutIntervalForRequest: requestTimeout, timeoutIntervalForResource: resourceTimeout)
            }
        )

        let credentialStoreResolver = CredentialStoreState.Resolver().eraseToAnyResolver()
        let credentialEnvironment = environmentFactory.makeCredentialEnvironment()
        let credentialStoreMachine = StateMachine(
            resolver: credentialStoreResolver,
            environment: credentialEnvironment
        )
        let credentialsClient = CredentialStoreOperationClient(
            credentialStoreStateMachine: credentialStoreMachine)

        let authResolver = AuthState.Resolver().eraseToAnyResolver()
        let authEnvironment = environmentFactory.makeAuthEnvironment(credentialsClient: credentialsClient)

        let authStateMachine = StateMachine(resolver: authResolver, environment: authEnvironment)

        let hubEventHandler = AuthHubEventHandler()
        // A keychain failure here has always been thrown to the app as `configure(using:)`'s error.
        let analyticsHandler = try EngineCredentialStoreError.rethrowingPublicError {
            try UserPoolAnalytics(
                authConfiguration.getUserPoolConfiguration(),
                credentialStoreEnvironment: credentialEnvironment.credentialStoreEnvironment
            )
        }

        configure(
            authConfiguration: authConfiguration,
            authEnvironment: authEnvironment,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreMachine,
            hubEventHandler: hubEventHandler,
            analyticsHandler: analyticsHandler
        )
    }

    func configure(
        authConfiguration: AuthConfiguration,
        authEnvironment: AuthEnvironment,
        authStateMachine: AuthStateMachine,
        credentialStoreStateMachine: CredentialStoreStateMachine,
        hubEventHandler: AuthHubEventBehavior,
        analyticsHandler: UserPoolAnalyticsBehavior,
        queue: OperationQueue = OperationQueue()
    ) {

        self.authConfiguration = authConfiguration
        self.queue = queue
        self.queue.maxConcurrentOperationCount = 1
        self.authEnvironment = authEnvironment
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        internalConfigure()
        listenToStateMachineChanges()
        self.hubEventHandler = hubEventHandler
        self.analyticsHandler = analyticsHandler
        taskQueue = TaskQueue()
    }

    // MARK: - Configure Helpers
    private func makeUserPool() throws -> CognitoUserPoolBehavior {
        switch authConfiguration {
        case .userPools(let userPoolConfig), .userPoolsAndIdentityPools(let userPoolConfig, _):
            let configuration = try CognitoIdentityProviderClient.CognitoIdentityProviderClientConfiguration(
                region: userPoolConfig.region,
                signingRegion: userPoolConfig.region,
                endpointResolver: userPoolConfig.endpoint?.resolver
            )

            if var httpClientEngineProxy {
                httpClientEngineProxy.target = baseClientEngine(for: configuration)
                configuration.httpClientEngine = UserAgentSettingClientEngine(
                    target: httpClientEngineProxy
                )
            } else {
                configuration.httpClientEngine = .userAgentEngine(for: configuration)
            }

            if let requestTimeout = networkPreferences?.timeoutIntervalForRequest {
                configuration.httpClientConfiguration = HttpClientConfiguration(connectTimeout: requestTimeout)
            }

            if let maxRetryUnwrapped = networkPreferences?.maxRetryCount {
                configuration.retryStrategyOptions = RetryStrategyOptions(
                    backoffStrategy: ExponentialBackoffStrategy(),
                    maxRetriesBase: Int(maxRetryUnwrapped)
                )
            }

            let authService = AWSAuthService()
            configuration.awsCredentialIdentityResolver = authService.getCredentialIdentityResolver()

            return CognitoIdentityProviderClient(config: configuration)
        default:
            fatalError()
        }
    }

    private func makeIdentityClient() throws -> CognitoIdentityBehavior {
        switch authConfiguration {
        case .identityPools(let identityPoolConfig), .userPoolsAndIdentityPools(_, let identityPoolConfig):
            let configuration = try CognitoIdentityClient.CognitoIdentityClientConfiguration(
                region: identityPoolConfig.region
            )
            configuration.httpClientEngine = .userAgentEngine(for: configuration)

            if let requestTimeout = networkPreferences?.timeoutIntervalForRequest {
                configuration.httpClientConfiguration = HttpClientConfiguration(connectTimeout: requestTimeout)
            }

            if let maxRetryUnwrapped = networkPreferences?.maxRetryCount {
                configuration.retryStrategyOptions = RetryStrategyOptions(
                    backoffStrategy: ExponentialBackoffStrategy(),
                    maxRetriesBase: Int(maxRetryUnwrapped)
                )
            }

            let authService = AWSAuthService()
            configuration.awsCredentialIdentityResolver = authService.getCredentialIdentityResolver()

            return CognitoIdentityClient(config: configuration)
        default:
            fatalError()
        }
    }

    /// Thrown by the Cognito client factories when the plugin that configured the environment is gone.
    private static func releasedPluginError() -> AuthError {
        AuthError.configuration(
            "The AWSCognitoAuthPlugin instance that configured this operation has been released.",
            "Keep a reference to the plugin, or add it to Amplify, while it is in use."
        )
    }

    private static func makeURLSession(
        timeoutIntervalForRequest: TimeInterval?,
        timeoutIntervalForResource: TimeInterval?
    ) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil

        if let timeoutIntervalForRequest {
            configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        }

        if let timeoutIntervalForResource {
            configuration.timeoutIntervalForResource = timeoutIntervalForResource
        }

        return URLSession(configuration: configuration)
    }

    private func makeUserPoolAnalytics() -> UserPoolAnalyticsBehavior {
        return analyticsHandler
    }

    private static func makeCredentialStore(
        authConfiguration: AuthConfiguration,
        accessGroup: String?,
        migrateKeychainItems: Bool
    ) -> AmplifyAuthCredentialStoreBehavior {
        return AWSCognitoAuthCredentialStore(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrateKeychainItems
        )
    }

    /// What `KeychainStore(service:)` operates on: no access group, logging under `KeychainStore`.
    private static func makeLegacyKeychainStore(service: String) -> any KeychainItemStoreBehavior {
        EngineKeychainStore.makeItemStore(service: service)
    }

    /// The analytics fallback for a released plugin: no Pinpoint metadata.
    private struct NoUserPoolAnalytics: UserPoolAnalyticsBehavior {
        func analyticsMetadata() async -> CognitoIdentityProviderClientTypes.AnalyticsMetadataType? {
            nil
        }
    }

    private func internalConfigure() {
        let request = AuthConfigureRequest(authConfiguration: authConfiguration)
        let operation = AuthConfigureOperation(
            request: request,
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine
        )
        queue.addOperation(operation)
    }
}
