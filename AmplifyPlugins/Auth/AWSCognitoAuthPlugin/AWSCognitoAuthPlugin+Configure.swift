//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSCore
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

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
        do {
            // Convert the JSONValue to [String: Any] dictionary to be used by AWSMobileClient
            let configurationData =  try JSONEncoder().encode(jsonValueConfiguration)
            let authConfig = (try? JSONSerialization.jsonObject(with: configurationData, options: [])
                as? [String: Any]) ?? [:]
            AWSInfo.configureDefaultAWSInfo(authConfig)
            let awsMobileClient = try awsMobileClientAdapter(from: jsonValueConfiguration)
            try awsMobileClient.initialize()
            let authenticationProvider = AuthenticationProviderAdapter(awsMobileClient: awsMobileClient)
            let authorizationProvider = AuthorizationProviderAdapter(awsMobileClient: awsMobileClient)
            let userService = AuthUserServiceAdapter(awsMobileClient: awsMobileClient)
            let deviceService = AuthDeviceServiceAdapter(awsMobileClient: awsMobileClient)
            let hubEventHandler = AuthHubEventHandler()
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            configure(authenticationProvider: authenticationProvider,
                      authorizationProvider: authorizationProvider,
                      userService: userService,
                      deviceService: deviceService,
                      hubEventHandler: hubEventHandler,
                      authConfig: jsonValueConfiguration,
                      queue: operationQueue)
        } catch let authError as AuthError {
            throw authError

        } catch {
            let amplifyError = AuthError.configuration(
                "Error configuring \(String(describing: self))",
                """
                There was an error configuring the plugin. See the underlying error for more details.
                """,
                error)
            throw amplifyError
        }
    }

    func awsMobileClientAdapter(from authConfiguration: JSONValue) throws -> AWSMobileClientBehavior {
        let identityPoolConfig = identityPoolServiceConfiguration(from: authConfiguration)
        let userPoolConfig = try userPoolServiceConfiguration(from: authConfiguration)

        // Auth plugin require atleast one of the Cognito service to work. Throw an error if both the service
        // configuration are nil.
        guard identityPoolConfig != nil || userPoolConfig != nil else {
            throw AuthError.configuration(
                "Error configuring \(String(describing: self))",
                """
                Could not read Cognito Service configuration from the auth configuration. Make sure that auth category
                is properly configured and auth information are present in the configuration. You can use Amplify CLI to
                configure the auth category.
                """)

        }
        return AWSMobileClientAdapter(userPoolConfiguration: userPoolConfig,
                                      identityPoolConfiguration: identityPoolConfig)
    }

    func identityPoolServiceConfiguration(from authConfiguration: JSONValue) -> AmplifyAWSServiceConfiguration? {
        let regionKeyPath = "CredentialsProvider.CognitoIdentity.Default.Region"
        guard case .string(let regionString) = authConfiguration.value(at: regionKeyPath) else {
            Amplify.Logging.info("""
                Cognito Identity Pool information is missing from the configuration. This is expected if you are not
                using an Identity Pool, otherwise check your configuration to make sure you specify a `Region`,
                `PoolId`, under `CognitoIdentity` > `Default`.
                See https://docs.amplify.aws/lib/auth/existing-resources/q/platform/ios for more details.
                """)
            return nil
        }
        let region = (regionString as NSString).aws_regionTypeValue()
        let anonymousCredentialProvider = AWSAnonymousCredentialsProvider()
        let service = AmplifyAWSServiceConfiguration(region: region, credentialsProvider: anonymousCredentialProvider)
        setUserPreferencesForService(service: service)
        return service
    }

    func setUserPreferencesForService(service: AmplifyAWSServiceConfiguration) {
        guard let networkPreferences = networkPreferences else {
            return
        }
        service.maxRetryCount = networkPreferences.maxRetryCount
        service.timeoutIntervalForRequest = networkPreferences.timeoutIntervalForRequest
        service.timeoutIntervalForResource = networkPreferences.timeoutIntervalForResource
    }

    func userPoolServiceConfiguration(from authConfiguration: JSONValue) throws -> AmplifyAWSServiceConfiguration? {
        let regionKeyPath = "CognitoUserPool.Default.Region"
        guard case .string(let regionString) = authConfiguration.value(at: regionKeyPath) else {
            Amplify.Logging.warn("Could not read Cognito user pool information from the configuration.")
            return nil
        }
        let region = (regionString as NSString).aws_regionTypeValue()

        let service: AmplifyAWSServiceConfiguration
        if  let endpoint = try resolveCognitoOverrideEndpoint(using: authConfiguration, region: region) {
            service = AmplifyAWSServiceConfiguration(region: region, endpoint: endpoint)
        } else {
            service = AmplifyAWSServiceConfiguration(region: region)
        }
        setUserPreferencesForService(service: service)
        return service
    }

    func resolveCognitoOverrideEndpoint(
        using authConfiguration: JSONValue,
        region: AWSRegionType) throws -> AWSEndpoint? {

            let endpointKeyPath = "CognitoUserPool.Default.Endpoint"
            guard case .string(let endpointString) = authConfiguration.value(at: endpointKeyPath) else {
                return nil
            }

            let amplifyError = AuthError.configuration(
                "Error configuring \(String(describing: self))",
            """
            Invalid Endpoint value \(endpointString). Expected a fully-qualified hostname.
            """)

            guard (URLComponents(string: endpointString)?.scheme ?? "").isEmpty else {
                throw amplifyError
            }

            let endpointStringWithScheme = "https://" + endpointString
            guard
                let components = URLComponents(string: endpointStringWithScheme),
                components.path == "",
                let url = components.url
            else {
                throw amplifyError
            }

            return AWSEndpoint(region: region, service: .CognitoIdentityProvider, url: url)
        }

    // MARK: Internal
    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - authenticationProvider: Provider that gives authentication abilities
    ///   - authorizationProvider: Provider that gives authorization abilities
    ///   - queue: The queue which operations are stored and dispatched for asychronous processing.
    func configure(authenticationProvider: AuthenticationProviderBehavior,
                   authorizationProvider: AuthorizationProviderBehavior,
                   userService: AuthUserServiceBehavior,
                   deviceService: AuthDeviceServiceBehavior,
                   hubEventHandler: AuthHubEventBehavior,
                   authConfig: JSONValue = JSONValue.object([:]),
                   queue: OperationQueue = OperationQueue()) {
        self.authenticationProvider = authenticationProvider
        self.authorizationProvider = authorizationProvider
        self.userService = userService
        self.deviceService = deviceService
        self.hubEventHandler = hubEventHandler
        configuration = authConfig
        self.queue = queue
    }
}
