//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Construction, registry binding and lifetime.
final class ClientConstructionTests: XCTestCase {

    private var harness: ClientHarness!

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Construction does no I/O and is synchronous

    /// Compile-time guard as much as a runtime one: this test is synchronous, so it would not compile if
    /// construction became `async`.
    ///
    /// - Given: a stored, signed-in session and a store that logs every keychain call
    /// - When: a client is constructed, with the restore not scheduled
    /// - Then:
    ///    - construction is synchronous, and makes no keychain call at all
    func testConstructionIsSynchronousAndTouchesNoStorage() throws {
        try harness.signIn(.default)

        let client = try harness.client()

        XCTAssertEqual(client.sessionId, .default)
        XCTAssertEqual(harness.keychain.readAccounts, [])
        XCTAssertFalse(harness.keychain.hasMutations)
    }

    // MARK: Sharing

    /// - Given: two clients constructed with the same session ID and configuration
    /// - When: their sessions are compared
    /// - Then:
    ///    - both are handles onto one core, built once, with one engine
    func testSameSessionIDSharesOneCore() throws {
        let first = try harness.client(ClientFixtures.id("work"))
        let second = try harness.client(ClientFixtures.id("work"))

        XCTAssertTrue(first.core === second.core)
        XCTAssertEqual(harness.engines.count, 1)
        XCTAssertEqual(harness.registry.liveSessionIDs, [ClientFixtures.id("work")])
    }

    /// Session IDs are case-sensitive; merging "Work" and "work" would silently cross credentials.
    ///
    /// - Given: clients for `"Work"` and `"work"`
    /// - When: both are constructed
    /// - Then:
    ///    - neither throws, and they are two different sessions
    func testSessionIDsDifferingOnlyInCaseAreDifferentSessions() throws {
        let upper = try harness.client(ClientFixtures.id("Work"))
        let lower = try harness.client(ClientFixtures.id("work"))

        XCTAssertFalse(upper.core === lower.core)
        XCTAssertEqual(harness.engines.count, 2)
    }

    // MARK: Mismatch

    private func assertMismatch(
        _ description: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        expectingMessage fragment: String,
        _ construct: () throws -> AmplifyCognitoClient
    ) {
        XCTAssertThrowsError(try construct(), description, file: file, line: line) { error in
            let error = error as? AuthClientError
            XCTAssertEqual(error?.isMismatch(for: ClientFixtures.id("work")), true, "\(String(describing: error))", file: file, line: line)
            XCTAssertEqual(
                error?.errorDescription.contains(fragment),
                true,
                "\(String(describing: error?.errorDescription))",
                file: file,
                line: line
            )
        }
    }

    /// Every row of the design's mismatch table: same session ID, contradictory settings.
    ///
    /// - Given: a live session `"work"` built with the default configuration and no escape hatch
    /// - When: another client for `"work"` is constructed with: another app client ID; an app client
    ///   secret; another region; a password policy; a hosted UI domain; an escape-hatch closure; no
    ///   identity pool; another user pool; another access group
    /// - Then:
    ///    - each throws `sessionConfigurationMismatch` for `"work"`: "different settings" for the same
    ///      record, "different user pool, identity pool or keychain access group" for a different record
    ///    - the live session is untouched and still joinable with the original configuration
    func testMismatchedConfigurationThrowsForEveryRow() throws {
        let work = ClientFixtures.id("work")
        let original = try harness.client(work)
        let userPool = ClientFixtures.userPool

        assertMismatch("another app client", expectingMessage: "different settings") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(poolId: userPool.poolId, appClientId: "app-client-2", region: userPool.region),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("an app client secret", expectingMessage: "different settings") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(poolId: userPool.poolId, appClientId: userPool.appClientId, region: userPool.region, appClientSecret: "s"),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("another region", expectingMessage: "different settings") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(poolId: userPool.poolId, appClientId: userPool.appClientId, region: "eu-west-1"),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("a password policy", expectingMessage: "different settings") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(
                    poolId: userPool.poolId,
                    appClientId: userPool.appClientId,
                    region: userPool.region,
                    passwordPolicy: .init(minLength: 12)
                ),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("a hosted UI domain", expectingMessage: "different settings") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(
                    poolId: userPool.poolId,
                    appClientId: userPool.appClientId,
                    region: userPool.region,
                    oauth: .init(
                        domain: "app.auth.us-east-1.amazoncognito.com",
                        scopes: ["openid"],
                        redirectSignInURIs: ["app://in/"],
                        redirectSignOutURIs: ["app://out/"]
                    )
                ),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("an escape hatch on only one handle", expectingMessage: "different settings") {
            try harness.client(work, configureUserPoolClient: { _ in })
        }
        assertMismatch("no identity pool", expectingMessage: "different user pool, identity pool or keychain access group") {
            try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
        }
        assertMismatch("another user pool", expectingMessage: "different user pool, identity pool or keychain access group") {
            try harness.client(work, configuration: ClientFixtures.make(
                userPool: .init(poolId: "us-east-1_Other", appClientId: userPool.appClientId, region: userPool.region),
                identityPool: ClientFixtures.identityPool
            ))
        }
        assertMismatch("another access group", expectingMessage: "different user pool, identity pool or keychain access group") {
            try harness.client(work, accessGroup: "group.shared")
        }

        XCTAssertTrue(try harness.client(work).core === original.core)
        XCTAssertEqual(harness.engines.count, 1)
    }

    /// A user pool with every setting, where each argument replaces one of them.
    private func settingsConfiguration(
        poolId: String = ClientFixtures.userPool.poolId,
        appClientId: String = ClientFixtures.userPool.appClientId,
        region: String = ClientFixtures.userPool.region,
        domain: String = "app.auth.us-east-1.amazoncognito.com",
        scopes: [String] = ["openid", "email"],
        redirectSignInURIs: [String] = ["app://in/"],
        redirectSignOutURIs: [String] = ["app://out/"],
        identityProviders: [String] = ["GOOGLE"],
        responseType: String = "code",
        passwordPolicy: AuthClientConfiguration.PasswordPolicy = .init(minLength: 8, requiresNumbers: true),
        standardRequiredAttributes: [AuthClientUserAttributeKey] = [.email],
        mfaEnforcement: AuthClientConfiguration.MFAEnforcement? = .optional,
        mfaMethods: [AuthClientMFAType] = [.sms, .totp],
        unauthenticatedIdentitiesEnabled: Bool? = nil
    ) -> AuthClientConfiguration {
        ClientFixtures.make(
            userPool: .init(
                poolId: poolId,
                appClientId: appClientId,
                region: region,
                oauth: .init(
                    domain: domain,
                    scopes: scopes,
                    redirectSignInURIs: redirectSignInURIs,
                    redirectSignOutURIs: redirectSignOutURIs,
                    identityProviders: identityProviders,
                    responseType: responseType
                ),
                passwordPolicy: passwordPolicy,
                usernameAttributes: [.email],
                standardRequiredAttributes: standardRequiredAttributes,
                verificationMechanisms: [.email],
                mfaEnforcement: mfaEnforcement,
                mfaMethods: mfaMethods
            ),
            identityPool: .init(
                poolId: ClientFixtures.identityPool.poolId,
                region: ClientFixtures.identityPool.region,
                unauthenticatedIdentitiesEnabled: unauthenticatedIdentitiesEnabled
            )
        )
    }

    /// The fingerprint is what the engine is configured with, so settings the engine never receives do not
    /// split a session.
    ///
    /// - Given: a live session `"work"` built with every user-pool setting, and a live session `"plain"`
    ///   built from pool IDs alone
    /// - When: more clients are constructed for them with settings the engine never receives, or with a
    ///   setting the engine does receive
    /// - Then:
    ///    - `"work"` is joined despite reordered scopes, extra redirect URIs, other identity providers and
    ///      response type, another MFA enforcement and method list, stated guest access, and extra
    ///      standard attributes the engine drops
    ///    - `"plain"` is joined by the same pools carrying only such settings, as a configuration read
    ///      from `amplify_outputs` would
    ///    - another pool, app client, region, password policy or hosted-UI domain still throws
    func testSettingsTheEngineDoesNotReceiveDoNotSplitASession() throws {
        let work = ClientFixtures.id("work")
        let original = try harness.client(work, configuration: settingsConfiguration())

        let joining: [(String, AuthClientConfiguration)] = [
            ("reordered scopes", settingsConfiguration(scopes: ["email", "openid"])),
            ("extra redirect URIs", settingsConfiguration(
                redirectSignInURIs: ["app://in/", "https://example.com/in"],
                redirectSignOutURIs: ["app://out/", "https://example.com/out"]
            )),
            ("other identity providers", settingsConfiguration(identityProviders: ["FACEBOOK", "GOOGLE"])),
            ("another response type", settingsConfiguration(responseType: "token")),
            ("another MFA enforcement", settingsConfiguration(mfaEnforcement: .required)),
            ("another MFA method list", settingsConfiguration(mfaMethods: [.totp])),
            ("guest access stated", settingsConfiguration(unauthenticatedIdentitiesEnabled: true)),
            ("attributes the engine drops", settingsConfiguration(standardRequiredAttributes: [.email, .locale, .sub]))
        ]
        for (description, configuration) in joining {
            XCTAssertTrue(try harness.client(work, configuration: configuration).core === original.core, description)
        }

        let plain = ClientFixtures.id("plain")
        let bare = try harness.client(plain)
        let fromOutputs = ClientFixtures.make(
            userPool: .init(
                poolId: ClientFixtures.userPool.poolId,
                appClientId: ClientFixtures.userPool.appClientId,
                region: ClientFixtures.userPool.region,
                standardRequiredAttributes: [.sub, .zoneInfo],
                mfaEnforcement: .off,
                mfaMethods: [.sms]
            ),
            identityPool: .init(
                poolId: ClientFixtures.identityPool.poolId,
                region: ClientFixtures.identityPool.region,
                unauthenticatedIdentitiesEnabled: false
            )
        )
        XCTAssertTrue(try harness.client(plain, configuration: fromOutputs).core === bare.core)

        assertMismatch("another user pool", expectingMessage: "different user pool, identity pool or keychain access group") {
            try harness.client(work, configuration: settingsConfiguration(poolId: "us-east-1_Other"))
        }
        assertMismatch("another app client", expectingMessage: "different settings") {
            try harness.client(work, configuration: settingsConfiguration(appClientId: "app-client-2"))
        }
        assertMismatch("another region", expectingMessage: "different settings") {
            try harness.client(work, configuration: settingsConfiguration(region: "eu-west-1"))
        }
        assertMismatch("another password policy", expectingMessage: "different settings") {
            try harness.client(work, configuration: settingsConfiguration(passwordPolicy: .init(minLength: 12)))
        }
        assertMismatch("another hosted-UI domain", expectingMessage: "different settings") {
            try harness.client(work, configuration: settingsConfiguration(domain: "other.auth.us-east-1.amazoncognito.com"))
        }
        XCTAssertEqual(harness.engines.count, 2)
    }

    // MARK: The escape hatch

    /// - Given: an escape-hatch closure that records it ran and sets a custom value
    /// - When: two handles that both customize are constructed for one session
    /// - Then:
    ///    - they join; the first handle's closure was applied to the session's SDK client, and the
    ///      second handle's never ran
    func testEscapeHatchIsAppliedOnceAndNotOnJoin() throws {
        let work = ClientFixtures.id("work")
        let firstCalls = CallCounter()
        let secondCalls = CallCounter()

        let first = try harness.client(work, configureUserPoolClient: { config in
            firstCalls.increment()
            config.maxAttempts = 7
        })
        let second = try harness.client(work, configureUserPoolClient: { _ in secondCalls.increment() })

        XCTAssertTrue(first.core === second.core)
        XCTAssertEqual(firstCalls.count, 1)
        XCTAssertEqual(secondCalls.count, 0)
        XCTAssertEqual(first.getUserPoolClient()?.config.maxAttempts, 7)
    }

    /// - Given: a session with both pools
    /// - When: its escape hatches are read from two handles
    /// - Then:
    ///    - both return the very SDK clients the session's engine was built with
    func testEscapeHatchesReturnTheEnginesClients() throws {
        let first = try harness.client()
        let second = try harness.client()
        let engine = try XCTUnwrap(harness.engine(for: .default))

        XCTAssertNotNil(first.getUserPoolClient())
        XCTAssertTrue(first.getUserPoolClient() === engine.context.clients.userPool)
        XCTAssertTrue(first.getIdentityClient() === engine.context.clients.identity)
        XCTAssertTrue(second.getUserPoolClient() === first.getUserPoolClient())
        XCTAssertEqual(engine.context.sessionId, .default)
        XCTAssertEqual(engine.context.namespace, StorageFixtures.namespace)
    }

    /// - Given: a user-pool-only and an identity-pool-only configuration
    /// - When: clients are constructed for each
    /// - Then:
    ///    - the escape hatch for the missing pool is `nil`, rather than a client for nothing
    func testEscapeHatchIsNilForAMissingPool() throws {
        let poolOnly = try harness.client(ClientFixtures.id("pool"), configuration: ClientFixtures.userPoolOnlyConfiguration)
        let identityOnly = try harness.client(ClientFixtures.id("identity"), configuration: ClientFixtures.identityPoolOnlyConfiguration)

        XCTAssertNotNil(poolOnly.getUserPoolClient())
        XCTAssertNil(poolOnly.getIdentityClient())
        XCTAssertNil(identityOnly.getUserPoolClient())
        XCTAssertNotNil(identityOnly.getIdentityClient())
    }

    // MARK: Construction failures

    /// - Given: SDK clients whose configuration throws
    /// - When: a client is constructed
    /// - Then:
    ///    - it throws `AuthClientError.configuration` carrying the SDK error, and no session is registered
    func testSDKConfigurationErrorBecomesConfigurationError() {
        harness.useClientsFactory { _, _ in throw FixtureError(description: "bad region") }

        XCTAssertThrowsError(try harness.client()) { error in
            guard case .configuration(_, _, let underlying) = error as? AuthClientError else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual((underlying as? FixtureError)?.description, "bad region")
        }
        XCTAssertEqual(harness.registry.entryCount, 0)
    }

    /// - Given: an engine factory that throws
    /// - When: a client is constructed, and then constructed again once the factory recovers
    /// - Then:
    ///    - the first construction throws the error and registers nothing; the second succeeds
    func testEngineCreationFailureRegistersNothing() throws {
        harness.failEngineCreation(with: AuthClientError.unknown("no engine", "retry"))

        XCTAssertThrowsError(try harness.client())
        XCTAssertEqual(harness.registry.entryCount, 0)

        harness.failEngineCreation(with: nil)
        XCTAssertNoThrow(try harness.client())
    }

    // MARK: Lifetime

    /// - Given: two handles on one session, and a weak reference to its core
    /// - When: both handles are dropped, and a new client for the session is constructed
    /// - Then:
    ///    - the core is released once the last handle goes, and the registry entry is pruned
    ///    - the new construction builds a fresh core, with a fresh engine
    func testLastHandleReleaseFreesTheCoreAndANewConstructionRebuilds() async throws {
        var first: AmplifyCognitoClient? = try harness.client()
        var second: AmplifyCognitoClient? = try harness.client()
        weak let probe = first?.core

        first = nil
        XCTAssertNotNil(probe, "one handle still holds the session")
        second = nil
        XCTAssertNil(probe)
        _ = (first, second)
        await waitUntil("the released session is pruned") { harness.registry.entryCount == 0 }

        let rebuilt = try harness.client()
        XCTAssertEqual(harness.engines.count, 2)
        XCTAssertEqual(harness.registry.liveSessionIDs, [.default])
        _ = rebuilt
    }

    /// A prune scheduled by a released session can run after a new session has taken its place. It
    /// compares before it clears, so it leaves the new one alone.
    ///
    /// - Given: a session whose last handle is dropped, and a new session built for the same ID at once
    /// - When: the late prune for the old session runs
    /// - Then:
    ///    - the new session's entry survives, and a further handle joins the new session
    func testLatePruneLeavesTheRebuiltEntry() throws {
        var dropped: AmplifyCognitoClient? = try harness.client()
        dropped = nil
        _ = dropped
        let rebuilt = try harness.client()

        harness.registry.pruneIfReleased(.default)

        XCTAssertEqual(harness.registry.liveSessionIDs, [.default])
        XCTAssertTrue(try harness.client().core === rebuilt.core)
    }

    /// The registry-deadlock regression. A lookup that finds a live entry holds a strong reference to it
    /// under the registry lock. If the last handle is dropped at that moment, that temporary is the last
    /// reference, and the core is released — and its `deinit` runs — while the lock is held. On the
    /// mismatch path it dies at the `throw`. A `deinit` that pruned synchronously would re-take the
    /// non-recursive lock and deadlock; the core schedules its prune instead.
    ///
    /// - Given: a live session, and a registry hook that drops its only handle right after a lookup has
    ///   loaded the live entry, under the lock
    /// - When: a client with a mismatched configuration is constructed for the same session ID, on its
    ///   own thread
    /// - Then:
    ///    - it throws `sessionConfigurationMismatch` and returns, rather than deadlocking
    ///    - the core was released, and its scheduled prune empties the registry
    func testReleasingTheLastHandleUnderTheRegistryLockDoesNotDeadlock() async throws {
        let holder = HandleHolder()
        let registry = SessionCoreDependencies.Registry(didLoadLiveEntry: { _ in holder.drop() })
        harness = ClientHarness(registry: registry)
        let work = ClientFixtures.id("work")
        var original: AmplifyCognitoClient? = try harness.client(work)
        weak let probe = original?.core
        holder.hold(try XCTUnwrap(original))
        original = nil
        _ = original

        let returned = expectation(description: "the mismatched construction returns")
        let harness = harness!
        let thread = Thread {
            do {
                _ = try harness.client(work, accessGroup: "group.other")
                XCTFail("the mismatched construction must throw")
            } catch {
                XCTAssertEqual((error as? AuthClientError)?.isMismatch(for: work), true, "\(error)")
            }
            returned.fulfill()
        }
        thread.start()
        await fulfillment(of: [returned], timeout: 300)

        XCTAssertNil(probe, "the lookup's temporary was the last reference")
        await waitUntil("the scheduled prune runs") { harness.registry.entryCount == 0 }
    }
}
