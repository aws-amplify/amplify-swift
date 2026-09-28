//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Builds the engine's two environments from an engine configuration and the pieces a host supplies
/// `AWSCognitoAuthPlugin.configure(using:)` calls it, and so does the client, once per
/// session.
///
/// **Inputs.** The host supplies everything that depends on its own options or on Amplify:
/// - `makeUserPool` and `makeIdentityClient` build the Cognito SDK clients. Their construction (user agent,
///   HTTP engine proxy, timeouts, retry, credential identity resolver) stays with the host;
/// - `credentialStoreFactory` and `legacyKeychainStoreFactory` build the stores;
/// - `logger` is the environments' logger, for both of them;
/// - `userPoolAnalytics` returns the analytics handler. It is a factory because the plugin creates its handler
///   from the credential environment, after this factory has run;
/// - `makeURLSession` builds the hosted-UI session, which reads the host's network preferences.
///
/// Every closure is stored in an environment and called there, exactly where the environment called the
/// plugin's own factory before. None is called here, so construction timing is unchanged.
///
/// **Built here, with the code `+Configure.swift` used.** These have no Amplify or host-option dependency:
/// `CognitoUserPoolASF()`, `RandomStringGenerator()` and `HostedUIASWebAuthenticationSession()`.
///
/// **Two outputs**, because the auth environment needs the credential-store client, and the host builds that
/// client from a state machine over the credential environment:
/// 1. `makeCredentialEnvironment()`;
/// 2. `makeAuthEnvironment(credentialsClient:)`.
///
/// Access: the type, its initializer and both outputs are `package`. No input or output names an Amplify or
/// plugin-option type: `legacyKeychainStoreFactory` returns an `InternalAmplifyKeychain` item store.
package struct AuthEnvironmentFactory {

    let authConfiguration: AuthConfiguration
    let makeUserPool: UserPoolEnvironment.CognitoUserPoolFactory
    let makeIdentityClient: AuthorizationEnvironment.CognitoIdentityFactory
    let credentialStoreFactory: CredentialStoreEnvironment.AmplifyAuthCredentialStoreFactory
    let legacyKeychainStoreFactory: CredentialStoreEnvironment.KeychainStoreFactory
    let logger: any EngineScopedLogger
    let userPoolAnalytics: UserPoolEnvironment.CognitoUserPoolAnalyticsHandlerFactory
    let makeURLSession: HostedUIEnvironment.URLSessionFactory
    let makeHostedUISession: HostedUIEnvironment.HostedUISessionFactory
    let hostedUIIdentityPolicy: HostedUIIdentityPolicy
    let hostedUIIssuedRefreshToken: HostedUIEnvironment.IssuedRefreshTokenObserver?

    /// - Parameters:
    ///   - makeHostedUISession: The browser presenter of the hosted UI. The plugin keeps the default;
    ///     `AmplifyCognitoClient` injects a presenter per operation so it can cancel it.
    ///   - hostedUIIdentityPolicy: What a hosted-UI sign-in checks about the tokens it gets back.
    ///     The plugin keeps `.none`; the client passes one per operation.
    ///   - hostedUIIssuedRefreshToken: Told each refresh token the hosted UI's code exchange is issued. The plugin
    ///     keeps `nil`; the client hands it to the operation's issued-token tap.
    package init(
        authConfiguration: AuthConfiguration,
        makeUserPool: @escaping @Sendable () throws -> CognitoUserPoolBehavior,
        makeIdentityClient: @escaping @Sendable () throws -> CognitoIdentityBehavior,
        credentialStoreFactory: @escaping @Sendable () -> AmplifyAuthCredentialStoreBehavior,
        legacyKeychainStoreFactory: @escaping CredentialStoreEnvironment.KeychainStoreFactory,
        logger: any EngineScopedLogger,
        userPoolAnalytics: @escaping @Sendable () -> UserPoolAnalyticsBehavior,
        makeURLSession: @escaping @Sendable () -> URLSession,
        makeHostedUISession: @escaping HostedUIEnvironment.HostedUISessionFactory = { HostedUIASWebAuthenticationSession() },
        hostedUIIdentityPolicy: HostedUIIdentityPolicy = .none,
        hostedUIIssuedRefreshToken: HostedUIEnvironment.IssuedRefreshTokenObserver? = nil
    ) {
        self.hostedUIIssuedRefreshToken = hostedUIIssuedRefreshToken
        self.authConfiguration = authConfiguration
        self.makeUserPool = makeUserPool
        self.makeIdentityClient = makeIdentityClient
        self.credentialStoreFactory = credentialStoreFactory
        self.legacyKeychainStoreFactory = legacyKeychainStoreFactory
        self.logger = logger
        self.userPoolAnalytics = userPoolAnalytics
        self.makeURLSession = makeURLSession
        self.makeHostedUISession = makeHostedUISession
        self.hostedUIIdentityPolicy = hostedUIIdentityPolicy
    }

    /// The credential store machine's environment.
    package func makeCredentialEnvironment() -> CredentialEnvironment {
        CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: credentialStoreFactory,
                legacyKeychainStoreFactory: legacyKeychainStoreFactory
            ), logger: logger
        )
    }

    /// The auth machine's environment, over the client of the credential store machine.
    package func makeAuthEnvironment(credentialsClient: CredentialStoreStateBehavior) -> AuthEnvironment {

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
                logger: logger
            )

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
                logger: logger
            )

        case .userPoolsAndIdentityPools(
            let userPoolConfigurationData,
            let identityPoolConfigurationData
        ):
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
                logger: logger
            )
        }
    }

    private func authenticationEnvironment(userPoolConfigData: UserPoolConfigurationData) -> AuthenticationEnvironment {

        let srpAuthEnvironment = BasicSRPAuthEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeUserPool
        )
        let srpSignInEnvironment = BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment)
        let userPoolEnvironment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: makeUserPool,
            cognitoUserPoolASFFactory: { CognitoUserPoolASF() },
            cognitoUserPoolAnalyticsHandlerFactory: userPoolAnalytics
        )
        let hostedUIEnvironment = hostedUIEnvironment(userPoolConfigData)
        return BasicAuthenticationEnvironment(
            srpSignInEnvironment: srpSignInEnvironment,
            userPoolEnvironment: userPoolEnvironment,
            hostedUIEnvironment: hostedUIEnvironment
        )
    }

    private func hostedUIEnvironment(_ configuration: UserPoolConfigurationData) -> HostedUIEnvironment? {
        guard let hostedUIConfig = configuration.hostedUIConfig else {
            return nil
        }
        return BasicHostedUIEnvironment(
            configuration: hostedUIConfig,
            hostedUISessionFactory: makeHostedUISession,
            urlSessionFactory: makeURLSession,
            randomStringFactory: { RandomStringGenerator() },
            identityPolicy: hostedUIIdentityPolicy,
            issuedRefreshTokenObserver: hostedUIIssuedRefreshToken
        )
    }

    private func authorizationEnvironment(identityPoolConfigData: IdentityPoolConfigurationData) -> AuthorizationEnvironment {
        BasicAuthorizationEnvironment(
            identityPoolConfiguration: identityPoolConfigData,
            cognitoIdentityFactory: makeIdentityClient
        )
    }
}
