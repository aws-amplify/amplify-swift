//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// What a session engine is built from, and the environment each operation gets through the engine's
/// environment factory.
final class EngineResourcesTests: XCTestCase {

    private var keychain: TestKeychain!

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
    }

    override func tearDown() {
        keychain = nil
        super.tearDown()
    }

    private func resources(
        configuration: AuthClientConfiguration = ClientFixtures.configuration
    ) throws -> EngineResources {
        let pinpointKeychain = keychain.itemStore(service: LazyUserPoolAnalytics.pinpointContextService)
        return try EngineResources(
            authConfiguration: AuthConfiguration(client: configuration),
            clients: CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil),
            devices: DeviceRecordIO(store: keychain.deviceStore(for: StorageFixtures.namespace)),
            analytics: LazyUserPoolAnalytics(pinpointAppId: nil, keychain: pinpointKeychain)
        )
    }

    private func credentialsClient(for factory: AuthEnvironmentFactory) -> CredentialStoreOperationClient {
        CredentialStoreOperationClient(credentialStoreStateMachine: StateMachine(
            resolver: CredentialStoreState.Resolver().eraseToAnyResolver(),
            environment: factory.makeCredentialEnvironment()
        ))
    }

    // MARK: The resources

    /// A session engine's resources come from its context, with no I/O.
    ///
    /// - Given: a session engine context for both pools, whose SDK clients the core built
    /// - When:
    ///    - the resources are built from it
    /// - Then:
    ///    - the engine configuration is the 1:1 map of the client's; the SDK clients are the context's own
    ///      instances; analytics has no Pinpoint app, so it will never read; device records use the context's
    ///      namespace; the advanced-security client is the system's, `CognitoUserPoolASF`
    ///
    func testResourcesComeFromTheContext() throws {
        let clients = try CognitoServiceClients(configuration: ClientFixtures.configuration, configureUserPoolClient: nil)
        let context = SessionEngineContext(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            namespace: StorageFixtures.namespace,
            clients: clients
        )

        let resources = EngineResources(context: context)

        XCTAssertEqual(resources.authConfiguration, AuthConfiguration(client: ClientFixtures.configuration))
        XCTAssertTrue(resources.clients.userPool === clients.userPool)
        XCTAssertTrue(resources.clients.identity === clients.identity)
        XCTAssertFalse(resources.analytics.isEnabled)
        XCTAssertEqual(resources.devices.store.namespace, StorageFixtures.namespace)
        XCTAssertEqual(resources.logger.name, "AmplifyCognitoClient")
        XCTAssertTrue(resources.makeAdvancedSecurity() is CognitoUserPoolASF)
    }

    /// The engine's configuration is filled from the client's, field for field.
    ///
    /// - Given: the three pool shapes of the client configuration
    /// - When:
    ///    - the engine configuration is built
    /// - Then:
    ///    - it has the matching case, the pools' IDs, client ID and regions, `.userSRP`, and `nil` for the
    ///      endpoint, the client secret and the Pinpoint app
    ///
    func testEngineConfigurationForEveryPoolShape() {
        let userPool = UserPoolConfigurationData(poolId: StorageFixtures.userPoolId, clientId: "app-client-1", region: "us-east-1")
        let identityPool = IdentityPoolConfigurationData(poolId: StorageFixtures.identityPoolId, region: "us-east-1")

        XCTAssertEqual(AuthConfiguration(client: ClientFixtures.configuration), .userPoolsAndIdentityPools(userPool, identityPool))
        XCTAssertEqual(AuthConfiguration(client: ClientFixtures.userPoolOnlyConfiguration), .userPools(userPool))
        XCTAssertEqual(AuthConfiguration(client: ClientFixtures.identityPoolOnlyConfiguration), .identityPools(identityPool))
        XCTAssertEqual(userPool.authFlowType, .userSRP)
        XCTAssertNil(userPool.endpoint)
        XCTAssertNil(userPool.clientSecret)
        XCTAssertNil(userPool.pinpointAppId)
    }

    // MARK: The environment

    /// The credential environment holds this operation's store and the inert legacy keychain.
    ///
    /// - Given: resources and an operation's credential store
    /// - When:
    ///    - the credential environment is built through the factory and its two store factories are called
    /// - Then:
    ///    - the credential store is the operation's own instance, every time; every legacy service is inert:
    ///      reads are not found, writes are accepted and dropped, so AWSMobileClient data is never migrated;
    ///      and the keychain saw nothing
    ///
    func testCredentialEnvironmentUsesTheSlotStoreAndTheInertLegacyKeychain() throws {
        let resources = try resources()
        let credentialStore = ClientCredentialStore(slot: CredentialSlot(seed: nil), devices: resources.devices)
        let environment = resources.makeEnvironmentFactory(credentialStore: credentialStore)
            .makeCredentialEnvironment().credentialStoreEnvironment

        XCTAssertTrue(environment.amplifyCredentialStoreFactory() as AnyObject === credentialStore)
        XCTAssertTrue(environment.amplifyCredentialStoreFactory() as AnyObject === credentialStore)
        for service in ["com.amazonaws.AWSCognitoIdentityUserPool.clientId", "com.amazonaws.AWSMobileClient", "any"] {
            let legacy = environment.legacyKeychainStoreFactory(service)
            XCTAssertTrue(legacy is InertLegacyKeychain, service)
            XCTAssertTrue(try legacy.addIfAbsent(Data("x".utf8), key: "k"))
            XCTAssertThrowsError(try legacy.getData("k")) { error in
                XCTAssertEqual(error as? KeychainAccessError, .itemNotFound)
            }
        }
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// The auth environment returns the session's SDK clients and this engine's one analytics instance.
    ///
    /// - Given: resources for both pools
    /// - When:
    ///    - the auth environment is built through the factory and its client and analytics factories are
    ///      called twice each
    /// - Then:
    ///    - the user pool and identity factories return the escape hatches' instances (`===`); the analytics
    ///      factory returns the resources' instance both times, never a new one per request
    ///
    func testAuthEnvironmentReturnsTheSessionsClientsAndOneAnalyticsInstance() throws {
        let resources = try resources()
        let factory = resources.makeEnvironmentFactory(
            credentialStore: ClientCredentialStore(slot: CredentialSlot(seed: nil), devices: resources.devices)
        )
        let environment = factory.makeAuthEnvironment(credentialsClient: credentialsClient(for: factory))

        let userPoolEnvironment = environment.userPoolEnvironment
        for _ in 0 ..< 2 {
            XCTAssertTrue(try userPoolEnvironment.cognitoUserPoolFactory() as AnyObject === resources.clients.userPool)
            XCTAssertTrue(try environment.cognitoIdentityFactory() as AnyObject === resources.clients.identity)
            XCTAssertTrue(userPoolEnvironment.cognitoUserPoolAnalyticsHandlerFactory() as AnyObject === resources.analytics)
        }
        XCTAssertTrue(environment.logger is ClientEngineLogger)
    }

    /// A pool that is not configured has no SDK client, and asking for one is a configuration error.
    ///
    /// - Given: resources for one pool only, of each kind
    /// - When:
    ///    - the configured pool's client is asked for through the environment, and the missing one directly
    /// - Then:
    ///    - the configured pool's is the session's instance; the missing one throws the engine's
    ///      `configuration` error rather than crashing on a force unwrap
    ///
    func testAMissingPoolsClientIsAConfigurationError() throws {
        let identityOnly = try resources(configuration: ClientFixtures.identityPoolOnlyConfiguration)
        XCTAssertNil(identityOnly.clients.userPool)
        let factory = identityOnly.makeEnvironmentFactory(
            credentialStore: ClientCredentialStore(slot: CredentialSlot(seed: nil), devices: identityOnly.devices)
        )
        let environment = factory.makeAuthEnvironment(credentialsClient: credentialsClient(for: factory))
        let authorizationEnvironment = try XCTUnwrap(environment.authorizationEnvironment)
        XCTAssertTrue(try authorizationEnvironment.cognitoIdentityFactory() as AnyObject === identityOnly.clients.identity)
        XCTAssertNil(environment.authenticationEnvironment)

        let userPoolOnly = try resources(configuration: ClientFixtures.userPoolOnlyConfiguration)
        XCTAssertNil(userPoolOnly.clients.identity)
        XCTAssertThrowsError(try EngineResources.required(userPoolOnly.clients.identity, "identity pool")) { error in
            guard case .configuration = error as? EngineAuthError else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertThrowsError(try EngineResources.required(identityOnly.clients.userPool, "user pool")) { error in
            guard case .configuration = error as? EngineAuthError else {
                return XCTFail("\(error)")
            }
        }
    }

    /// The hosted UI's URL session is the plugin's with no network preferences.
    ///
    /// - Given: nothing
    /// - When:
    ///    - the resources' URL session factory is called
    /// - Then:
    ///    - its configuration has no URL cache
    ///
    func testURLSessionHasNoCache() {
        XCTAssertNil(EngineResources.makeURLSession().configuration.urlCache)
    }

    // MARK: One operation

    /// Building an operation seeds its slot and makes two fresh machines, with no I/O.
    ///
    /// - Given: resources, and the signed-in frozen payload
    /// - When:
    ///    - an operation is built from the payload, and another from no payload
    /// - Then:
    ///    - the first slot holds the payload's credentials and the second none; the credential store is over
    ///      that slot; both machines of each operation are not configured yet; the operations share no
    ///      machine; the keychain saw nothing
    ///
    func testMakeOperationSeedsTheSlotAndBuildsFreshMachines() async throws {
        let resources = try resources()
        let payload = try EnginePayloadFixtures.data("userPoolAndIdentityPool")

        let seeded = try resources.makeOperation(seed: payload)
        let empty = try resources.makeOperation(seed: nil)

        XCTAssertEqual(seeded.slot.current, .untouched(try EnginePayloadFixtures.credentials("userPoolAndIdentityPool")))
        XCTAssertEqual(empty.slot.current, .untouched(nil))
        XCTAssertTrue(seeded.credentialStore.slot === seeded.slot)
        let authState = await seeded.authMachine.currentState
        let credentialState = await seeded.credentialMachine.currentState
        XCTAssertEqual(authState, .notConfigured)
        XCTAssertEqual(credentialState, .notConfigured)
        XCTAssertFalse(seeded.authMachine === empty.authMachine)
        XCTAssertFalse(seeded.credentialMachine === empty.credentialMachine)
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// An operation cannot be built over a payload that is not credentials.
    ///
    /// - Given: resources, and bytes that are not a payload
    /// - When:
    ///    - an operation is built from them
    /// - Then:
    ///    - it throws the decoding error
    ///
    func testMakeOperationRefusesAnUndecodableSeed() throws {
        let resources = try resources()
        XCTAssertThrowsError(try resources.makeOperation(seed: Data("{}".utf8))) { error in
            XCTAssertTrue(error is DecodingError, "\(error)")
        }
    }

    // MARK: The logger

    /// The engine logs under the client's category, and a scope is a sub-category, never a session ID.
    ///
    /// - Given: the client's engine logger
    /// - When:
    ///    - it is scoped to each kind of engine scope
    /// - Then:
    ///    - the names are `AmplifyCognitoClient` and `AmplifyCognitoClient.<scope>`, the scope named as the
    ///      engine's default router names it
    ///
    func testLoggerNames() throws {
        let logger = ClientEngineLogger()
        XCTAssertEqual(logger.name, "AmplifyCognitoClient")
        let scopes: [(EngineLogScope, String)] = [
            (.category("MFAType"), "AmplifyCognitoClient.MFAType"),
            (.categoryNamespace("Authentication", "InitiateAuthSRP"), "AmplifyCognitoClient.InitiateAuthSRP"),
            (.namespace("KeychainStore"), "AmplifyCognitoClient.KeychainStore")
        ]
        for (scope, name) in scopes {
            XCTAssertEqual(try XCTUnwrap(logger.scoped(scope) as? ClientEngineLogger).name, name)
        }
    }
}
