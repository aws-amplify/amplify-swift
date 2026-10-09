//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsCore
@testable import InternalAWSCognitoAuth

/// The engine's environment factory: it builds what `+Configure.swift` built before, and it never
/// calls a host factory itself, so construction timing is unchanged.
final class AuthEnvironmentFactoryTests: XCTestCase {

    /// Counts how often each host factory is called, and records the legacy services asked for.
    final class Calls: @unchecked Sendable {
        private let lock = NSLock()
        private var counts: [String: Int] = [:]
        private var services: [String] = []

        func record(_ name: String, service: String? = nil) {
            lock.lock()
            defer { lock.unlock() }
            counts[name, default: 0] += 1
            if let service {
                services.append(service)
            }
        }

        func count(_ name: String) -> Int {
            lock.lock()
            defer { lock.unlock() }
            return counts[name, default: 0]
        }

        var total: Int {
            lock.lock()
            defer { lock.unlock() }
            return counts.values.reduce(0, +)
        }

        var legacyServices: [String] {
            lock.lock()
            defer { lock.unlock() }
            return services
        }
    }

    static let logger = AmplifyEngineLogRouter(scope: .categoryNamespace("Test", "AuthEnvironmentFactoryTests"))

    static func makeFactory(_ configuration: AuthConfiguration, calls: Calls) -> AuthEnvironmentFactory {
        AuthEnvironmentFactory(
            authConfiguration: configuration,
            makeUserPool: {
                calls.record("makeUserPool")
                return try Defaults.makeDefaultUserPool()
            },
            makeIdentityClient: {
                calls.record("makeIdentityClient")
                return try Defaults.makeIdentity()
            },
            credentialStoreFactory: {
                calls.record("credentialStoreFactory")
                return Defaults.makeAmplifyStore()
            },
            legacyKeychainStoreFactory: { service in
                calls.record("legacyKeychainStoreFactory", service: service)
                return Defaults.makeLegacyStore(service: service)
            },
            logger: logger,
            userPoolAnalytics: {
                calls.record("userPoolAnalytics")
                return MockAnalyticsHandler()
            },
            makeURLSession: {
                calls.record("makeURLSession")
                return URLSession(configuration: .ephemeral)
            }
        )
    }

    static let hostedUI = HostedUIConfigurationData(
        clientId: "hostedUIClientId",
        oauth: OAuthConfigurationData(
            domain: "example.auth.us-east-1.amazoncognito.com",
            scopes: ["openid"],
            signInRedirectURI: "myapp://signin/",
            signOutRedirectURI: "myapp://signout/"
        )
    )

    static func scope(of logger: any EngineScopedLogger) -> EngineLogScope? {
        (logger as? AmplifyEngineLogRouter)?.scope
    }

    /// Test that building both environments calls no host factory
    ///
    /// - Given: A factory over counting host factories, for every `AuthConfiguration` case
    /// - When:
    ///    - Both environments are built
    /// - Then:
    ///    - No host factory has been called: the environments hold them, as they held the plugin's own
    ///
    func testBuildingCallsNoHostFactory() {
        let configurations: [AuthConfiguration] = [
            .userPools(Defaults.makeDefaultUserPoolConfigData(withHostedUI: Self.hostedUI)),
            .identityPools(Defaults.makeIdentityConfigData()),
            Defaults.makeDefaultAuthConfigData(withHostedUI: Self.hostedUI)
        ]
        for configuration in configurations {
            let calls = Calls()
            let factory = Self.makeFactory(configuration, calls: calls)
            _ = factory.makeCredentialEnvironment()
            _ = factory.makeAuthEnvironment(credentialsClient: Defaults.makeCredentialStoreOperationBehavior())
            XCTAssertEqual(calls.total, 0, "\(configuration)")
        }
    }

    /// Test that the credential environment carries the configuration, the stores and the logger
    ///
    /// - Given: A factory over counting host factories
    /// - When:
    ///    - The credential environment is built, and its store factories are called
    /// - Then:
    ///    - It holds the configuration and the given logger
    ///    - Each store factory reaches the host's, once per call, with the service passed through
    ///
    func testCredentialEnvironment() {
        let calls = Calls()
        let configuration = Defaults.makeDefaultAuthConfigData()
        let environment = Self.makeFactory(configuration, calls: calls).makeCredentialEnvironment()

        XCTAssertEqual(environment.authConfiguration, configuration)
        XCTAssertEqual(Self.scope(of: environment.logger), Self.logger.scope)

        _ = environment.credentialStoreEnvironment.amplifyCredentialStoreFactory()
        _ = environment.credentialStoreEnvironment.legacyKeychainStoreFactory("service.one")
        _ = environment.credentialStoreEnvironment.legacyKeychainStoreFactory("service.two")
        XCTAssertEqual(calls.count("credentialStoreFactory"), 1)
        XCTAssertEqual(calls.count("legacyKeychainStoreFactory"), 2)
        XCTAssertEqual(calls.legacyServices, ["service.one", "service.two"])
        XCTAssertEqual(calls.total, 3)
    }

    /// Test the auth environment for a user pool with hosted UI and an identity pool
    ///
    /// - Given: A factory over `.userPoolsAndIdentityPools`, with a hosted-UI configuration
    /// - When:
    ///    - The auth environment is built, and every factory it holds is called
    /// - Then:
    ///    - It holds the configuration, both pool configurations, the credentials client and the logger
    ///    - Host factories are reached through the environment; the ASF, random-string and hosted-UI session
    ///      factories build the production types, as `+Configure.swift` did
    ///    - The SRP environment keeps its defaults
    ///
    func testAuthEnvironmentForBothPools() throws {
        let calls = Calls()
        let configuration = Defaults.makeDefaultAuthConfigData(withHostedUI: Self.hostedUI)
        let credentialsClient = Defaults.makeCredentialStoreOperationBehavior()
        let environment = Self.makeFactory(configuration, calls: calls)
            .makeAuthEnvironment(credentialsClient: credentialsClient)

        XCTAssertEqual(environment.configuration, configuration)
        XCTAssertEqual(environment.userPoolConfigData, configuration.getUserPoolConfiguration())
        XCTAssertEqual(environment.identityPoolConfigData, configuration.getIdentityPoolConfiguration())
        XCTAssertTrue(environment.credentialsClient is MockCredentialStoreOperationClient)
        XCTAssertEqual(Self.scope(of: environment.logger), Self.logger.scope)

        let userPoolEnvironment = environment.userPoolEnvironment
        XCTAssertEqual(userPoolEnvironment.userPoolConfiguration, configuration.getUserPoolConfiguration())
        _ = try userPoolEnvironment.cognitoUserPoolFactory()
        XCTAssertTrue(userPoolEnvironment.cognitoUserPoolASFFactory() is CognitoUserPoolASF)
        _ = userPoolEnvironment.cognitoUserPoolAnalyticsHandlerFactory()

        let srpEnvironment = try XCTUnwrap(environment.srpSignInEnvironment.srpAuthEnvironment as? BasicSRPAuthEnvironment)
        XCTAssertEqual(srpEnvironment.userPoolConfiguration, configuration.getUserPoolConfiguration())
        _ = try srpEnvironment.cognitoUserPoolFactory()
        XCTAssertEqual(srpEnvironment.srpConfiguration.nHexValue, SRPCommonConfig.nHexValue)
        XCTAssertEqual(srpEnvironment.srpConfiguration.gHexValue, SRPCommonConfig.gHexValue)

        let hostedUIEnvironment = try XCTUnwrap(environment.hostedUIEnvironment)
        XCTAssertEqual(hostedUIEnvironment.configuration, Self.hostedUI)
        XCTAssertTrue(hostedUIEnvironment.hostedUISessionFactory() is HostedUIASWebAuthenticationSession)
        XCTAssertTrue(hostedUIEnvironment.randomStringFactory() is RandomStringGenerator)
        _ = hostedUIEnvironment.urlSessionFactory()

        XCTAssertEqual(environment.identityPoolConfiguration, configuration.getIdentityPoolConfiguration())
        _ = try environment.cognitoIdentityFactory()

        XCTAssertEqual(calls.count("makeUserPool"), 2)
        XCTAssertEqual(calls.count("userPoolAnalytics"), 1)
        XCTAssertEqual(calls.count("makeURLSession"), 1)
        XCTAssertEqual(calls.count("makeIdentityClient"), 1)
        XCTAssertEqual(calls.total, 5)
    }

    /// Test the hosted-UI inputs a caller can inject
    ///
    /// - Given: A factory built with the plugin's defaults, and one given a presenter factory and an identity
    ///   policy
    /// - When:
    ///    - Each builds its auth environment
    /// - Then:
    ///    - The defaults give the production presenter and the `.none` policy; the injected ones are used as given
    ///
    func testHostedUIPresenterAndPolicyCanBeInjected() throws {
        let configuration = Defaults.makeDefaultAuthConfigData(withHostedUI: Self.hostedUI)
        let credentialsClient = Defaults.makeCredentialStoreOperationBehavior()
        let defaults = try XCTUnwrap(
            Self.makeFactory(configuration, calls: Calls())
                .makeAuthEnvironment(credentialsClient: credentialsClient).hostedUIEnvironment
        )
        XCTAssertTrue(defaults.hostedUISessionFactory() is HostedUIASWebAuthenticationSession)
        XCTAssertEqual(defaults.identityPolicy, .none)

        let presenter = MockHostedUISession(result: .success([]))
        let policy = HostedUIIdentityPolicy(verifiesTokenClaims: true, excludedSubjects: ["other"])
        let injected = try XCTUnwrap(
            AuthEnvironmentFactory(
                authConfiguration: configuration,
                makeUserPool: { try Defaults.makeDefaultUserPool() },
                makeIdentityClient: { try Defaults.makeIdentity() },
                credentialStoreFactory: { Defaults.makeAmplifyStore() },
                legacyKeychainStoreFactory: { Defaults.makeLegacyStore(service: $0) },
                logger: Self.logger,
                userPoolAnalytics: { MockAnalyticsHandler() },
                makeURLSession: { URLSession.shared },
                makeHostedUISession: { presenter },
                hostedUIIdentityPolicy: policy
            )
            .makeAuthEnvironment(credentialsClient: credentialsClient).hostedUIEnvironment
        )
        XCTAssertTrue(injected.hostedUISessionFactory() as AnyObject === presenter)
        XCTAssertEqual(injected.identityPolicy, policy)
    }

    /// Test the auth environment for a user pool alone, without hosted UI
    ///
    /// - Given: A factory over `.userPools`, with no hosted-UI configuration
    /// - When:
    ///    - The auth environment is built
    /// - Then:
    ///    - It has an authentication environment with no hosted-UI environment, and no authorization
    ///      environment or identity-pool configuration
    ///
    func testAuthEnvironmentForUserPoolOnly() {
        let userPool = Defaults.makeDefaultUserPoolConfigData()
        let environment = Self.makeFactory(.userPools(userPool), calls: Calls())
            .makeAuthEnvironment(credentialsClient: Defaults.makeCredentialStoreOperationBehavior())

        XCTAssertEqual(environment.userPoolConfigData, userPool)
        XCTAssertNil(environment.identityPoolConfigData)
        XCTAssertNotNil(environment.authenticationEnvironment)
        XCTAssertNil(environment.authorizationEnvironment)
        XCTAssertNil(environment.hostedUIEnvironment)
    }

    /// Test the auth environment for an identity pool alone
    ///
    /// - Given: A factory over `.identityPools`
    /// - When:
    ///    - The auth environment is built
    /// - Then:
    ///    - It has an authorization environment over the identity pool, and no authentication environment
    ///      or user-pool configuration
    ///
    func testAuthEnvironmentForIdentityPoolOnly() throws {
        let calls = Calls()
        let identityPool = Defaults.makeIdentityConfigData()
        let environment = Self.makeFactory(.identityPools(identityPool), calls: calls)
            .makeAuthEnvironment(credentialsClient: Defaults.makeCredentialStoreOperationBehavior())

        XCTAssertNil(environment.userPoolConfigData)
        XCTAssertEqual(environment.identityPoolConfigData, identityPool)
        XCTAssertNil(environment.authenticationEnvironment)
        let authorizationEnvironment = try XCTUnwrap(environment.authorizationEnvironment)
        XCTAssertEqual(authorizationEnvironment.identityPoolConfiguration, identityPool)
        _ = try authorizationEnvironment.cognitoIdentityFactory()
        XCTAssertEqual(calls.count("makeIdentityClient"), 1)
    }
}

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AuthEnvironmentFactoryPluginTests: XCTestCase, @unchecked Sendable {

    private var configureEvent: AuthConfigureEventWaiter!

    override func setUp() async throws {
        configureEvent = AuthConfigureEventWaiter()
    }

    override func tearDown() async throws {
        // Resetting while the plugin is still configuring traps in its Hub dispatch.
        await configureEvent.waitIfConfigureStarted()
        configureEvent = nil
        await Amplify.reset()
    }

    /// Test that the plugin builds its environments through the factory
    ///
    /// - Given: An `AWSCognitoAuthPlugin`
    /// - When:
    ///    - It is configured with an `amplify_outputs` that has a user pool with OAuth and an identity pool
    ///      (the configuration golden `full` input)
    /// - Then:
    ///    - Its auth environment has the plugin's logger scope, both pools, a hosted-UI environment and the
    ///      production ASF, random-string and hosted-UI session types
    ///
    func testPluginConfiguresThroughTheFactory() throws {
        let plugin = AWSCognitoAuthPlugin()
        try Amplify.add(plugin: plugin)
        let outputs = try AmplifyOutputsData.decodeAmplifyOutputsData(
            from: ConfigurationGoldenTests.inputData("full")
        )
        try Amplify.configure(outputs)

        let environment = try XCTUnwrap(plugin.authEnvironment)
        XCTAssertEqual(environment.configuration, try ConfigurationGoldenTests.buildConfiguration("full"))
        XCTAssertEqual(AuthEnvironmentFactoryTests.scope(of: environment.logger), AmplifyEngineLogRouter.pluginScope)
        XCTAssertNotNil(environment.userPoolConfigData)
        XCTAssertNotNil(environment.identityPoolConfigData)
        XCTAssertTrue(environment.userPoolEnvironment.cognitoUserPoolASFFactory() is CognitoUserPoolASF)
        let hostedUIEnvironment = try XCTUnwrap(environment.hostedUIEnvironment)
        XCTAssertTrue(hostedUIEnvironment.hostedUISessionFactory() is HostedUIASWebAuthenticationSession)
        XCTAssertTrue(hostedUIEnvironment.randomStringFactory() is RandomStringGenerator)
    }
}
