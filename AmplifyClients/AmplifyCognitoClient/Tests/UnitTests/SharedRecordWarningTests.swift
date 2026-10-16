//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The temporary warning that goes with the plugin bridge: when `.default` re-reads the shared
/// record and finds a different principal from the one it holds in memory, it logs one warning, once per core, at
/// `warn`, under `AmplifyCognitoClient.DefaultSession`, naming no one.
///
/// Each test alternates the Auth plugin's real credential store, `AWSCognitoAuthCredentialStore`, and the client (its
/// real record store, core and live engine, with scripted Cognito) over one in-memory keychain, as
/// `RollbackMatrixClientTests` does.
final class SharedRecordWarningTests: XCTestCase {

    private static let category = "AmplifyCognitoClient.DefaultSession"

    private var harness: ClientHarness!
    private var live: LiveEngineHarness!
    private var sink: SharedRecordWarningCapture!
    private let work = ClientFixtures.id("work")

    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        super.setUp()
        harness = ClientHarness()
        live = LiveEngineHarness()
        live.scriptIdentityPool()
        scriptRefreshKeepingTheUser()
        sink = SharedRecordWarningCapture()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() async throws {
        AmplifyLogging.removeSink(sink)
        sink = nil
        await harness.waitForBaseline()
        harness = nil
        live = nil
        try await super.tearDown()
    }

    // MARK: - The category

    /// - Given: the client's log areas
    /// - When: the warning's area is read
    /// - Then:
    ///    - its category is spelled `AmplifyCognitoClient.DefaultSession`
    func testTheWarningsCategory() {
        XCTAssertEqual(ClientLog.category(ClientLog.defaultSession), Self.category)
    }

    // MARK: - Warns

    /// - Given: `.default` restored as alice, from the plugin's record
    /// - When:
    ///    - the real plugin store saves bob, and the client refreshes
    /// - Then:
    ///    - exactly one warning with the exact text, at `warn`, under `AmplifyCognitoClient.DefaultSession`,
    ///      containing no user name, `sub`, identity ID or session ID
    func testAnotherUserWrittenByThePlugin_logsOnce() async throws {
        let client = try await restoredClient(holding: user("alice"))

        try await pluginSaves(user("bob"))
        await refresh(client)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        assertOneWarning(naming: ["alice", "bob", "sub-", LiveEngineFixtures.identityId])
    }

    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves a guest, and the client refreshes
    /// - Then:
    ///    - exactly one warning, naming no one
    func testAGuestWrittenOverTheUser_logsOnce() async throws {
        let client = try await restoredClient(holding: user("alice"))

        try pluginSaves(guest("us-east-1:guest-1"))
        await refresh(client)

        assertOneWarning(naming: ["alice", "sub-", "us-east-1:guest-1"])
    }

    /// A guest in memory replaced by a user counts.
    ///
    /// - Given: `.default` restored as a guest
    /// - When:
    ///    - the real plugin store saves bob, and the client refreshes
    /// - Then:
    ///    - exactly one warning, naming no one
    func testGuestInMemoryReplacedByAUser_logsOnce() async throws {
        let client = try await restoredClient(holding: guest("us-east-1:guest-1"))

        try await pluginSaves(user("bob"))
        await refresh(client)

        assertOneWarning(naming: ["bob", "sub-", "us-east-1:guest-1"])
    }

    /// A guest replaced by a user counts even when the user keeps the guest's identity ID.
    ///
    /// - Given: `.default` restored as a guest
    /// - When:
    ///    - the real plugin store saves bob, with the same identity ID, and the client refreshes
    /// - Then:
    ///    - exactly one warning, naming no one
    func testGuestReplacedByAUserWithTheSameIdentity_logsOnce() async throws {
        let client = try await restoredClient(holding: guest(LiveEngineFixtures.identityId))
        let bob = try await user("bob")
        guard case .userPoolAndIdentityPool(_, let identityId, _) = bob else {
            return XCTFail("bob should be signed in with both pools")
        }
        XCTAssertEqual(identityId, LiveEngineFixtures.identityId)

        try pluginSaves(bob)
        await refresh(client)

        assertOneWarning(naming: ["bob", "sub-", LiveEngineFixtures.identityId])
    }

    /// A different identity ID is a different guest.
    ///
    /// - Given: `.default` restored as a guest
    /// - When:
    ///    - the real plugin store saves a guest with another identity ID, and the client refreshes
    /// - Then:
    ///    - exactly one warning, naming neither identity
    func testGuestReplacedByAnotherGuest_logsOnce() async throws {
        let client = try await restoredClient(holding: guest("us-east-1:guest-1"))

        try pluginSaves(guest("us-east-1:guest-2"))
        await refresh(client)

        assertOneWarning(naming: ["us-east-1:guest-1", "us-east-1:guest-2"])
    }

    /// A federated identity ID counts as a principal.
    ///
    /// - Given: `.default` restored as a federated identity
    /// - When:
    ///    - the real plugin store saves a federation to another identity ID, and the client refreshes
    /// - Then:
    ///    - exactly one warning, naming neither identity
    func testFederatedReplacedByAnotherIdentity_logsOnce() async throws {
        let client = try await restoredClient(holding: federated("us-east-1:federated-1"))

        try pluginSaves(federated("us-east-1:federated-2"))
        await refresh(client)

        assertOneWarning(naming: ["us-east-1:federated-1", "us-east-1:federated-2"])
    }

    /// The re-read of a discarded write counts, not only the refresh's first read.
    ///
    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves bob while the client's refresh is at Cognito
    /// - Then:
    ///    - the refresh's guarded write is discarded, the re-read adopts bob, and exactly one warning is logged
    func testAnotherUserSavedDuringTheRefresh_logsOnce() async throws {
        let client = try await restoredClient(holding: user("alice"))
        let bob = try await user("bob")
        let keychain = pluginKeychain
        live.cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) in
            try Self.pluginStore(over: keychain).saveCredential(bob)
            return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens("alice", version: 2))
        }

        await refresh(client)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(try storedCredentials(), bob)
        assertOneWarning(naming: ["alice", "bob", "sub-"])
    }

    /// The sign-out's re-check after its revoke counts.
    ///
    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves bob while the client's sign-out revokes alice
    /// - Then:
    ///    - the sign-out is `.failed(.invalidState)`: bob is left signed in, and exactly one warning is logged
    func testAnotherUserSavedDuringTheSignOut_logsOnce() async throws {
        let client = try await restoredClient(holding: user("alice"))
        let bob = try await user("bob")
        let keychain = pluginKeychain
        live.cognito.once("RevokeToken") { (_: RevokeTokenInput) in
            try Self.pluginStore(over: keychain).saveCredential(bob)
            return RevokeTokenOutput()
        }

        let result = await client.signOut()

        XCTAssertEqual(result, .failed(SessionSignOut.supersededError()), "\(result)")
        XCTAssertEqual(try storedCredentials(), bob)
        assertOneWarning(naming: ["alice", "bob", "sub-"])
    }

    /// A label binds to the shared record as the store re-reads it: that re-read counts too.
    ///
    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves bob, and the client sets the session's label
    /// - Then:
    ///    - the session adopts bob, and exactly one warning is logged
    func testALabelSetOverAnotherUser_logsOnce() async throws {
        let client = try await restoredClient(holding: user("alice"))

        try await pluginSaves(user("bob"))
        try await client.setSessionLabel("Work")

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        assertOneWarning(naming: ["alice", "bob", "sub-", "Work"])
    }

    // MARK: - Logs nothing

    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store signs out, saving `noCredentials`, and the client refreshes; then, on a new core
    ///      restored as alice, the plugin store deletes its record, and the client refreshes
    /// - Then:
    ///    - each core is signed out, and nothing is logged under the category
    func testPluginSignOut_logsNothing() async throws {
        var client: AmplifyCognitoClient? = try await restoredClient(holding: user("alice"))
        try pluginSaves(.noCredentials)
        try await refresh(XCTUnwrap(client))
        let afterNoCredentials = await client?.currentSessionState()
        XCTAssertEqual(afterNoCredentials, .signedOut)
        client = nil
        await harness.waitForBaseline()

        client = try await restoredClient(holding: user("alice"))
        try pluginStore().deleteCredential()
        try await refresh(XCTUnwrap(client))
        let afterDeletion = await client?.currentSessionState()
        XCTAssertEqual(afterDeletion, .signedOut)

        XCTAssertEqual(sink.lines, [])
    }

    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves alice refreshed, and the client refreshes
    /// - Then:
    ///    - nothing is logged under the category
    func testSameUserRefreshedByThePlugin_logsNothing() async throws {
        let alice = try await userPayload("alice")
        let client = try await restoredClient(holding: AmplifyCredentials.decoded(alice))
        let refreshed = try await AmplifyCredentials.decoded(live.engine().refresh(alice, force: true))
        XCTAssertNotEqual(refreshed, try AmplifyCredentials.decoded(alice))

        try pluginSaves(refreshed)
        await refresh(client)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(sink.lines, [])
    }

    /// - Given: `.default` restored as a guest, then, on a new core, as a federated identity
    /// - When:
    ///    - each time, the real plugin store saves new credentials for the same identity ID, and the client refreshes
    /// - Then:
    ///    - nothing is logged under the category
    func testSameGuestRefreshedByThePlugin_logsNothing() async throws {
        var client: AmplifyCognitoClient? = try await restoredClient(holding: guest("us-east-1:guest-1"))
        try pluginSaves(guest("us-east-1:guest-1", version: 2))
        try await refresh(XCTUnwrap(client))
        client = nil
        await harness.waitForBaseline()

        client = try await restoredClient(holding: federated("us-east-1:federated-1"))
        try pluginSaves(federated("us-east-1:federated-1", version: 2))
        try await refresh(XCTUnwrap(client))

        XCTAssertEqual(sink.lines, [])
    }

    /// The client's own write is not another writer's: it never warns.
    ///
    /// - Given: `.default` restored as a guest
    /// - When:
    ///    - the client signs alice in over the guest, then refreshes
    /// - Then:
    ///    - the session is alice's, and nothing is logged under the category
    func testOwnSignInOverAGuest_logsNothing() async throws {
        let client = try await restoredClient(holding: guest("us-east-1:guest-1"))

        live.scriptSRP("alice")
        let signedIn = try await client.signIn(username: "alice", password: "password")
        await refresh(client)

        XCTAssertEqual(signedIn.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(sink.lines, [])
    }

    /// - Given: `.default` restored as alice, whose refresh token is then found revoked
    /// - When:
    ///    - the client signs bob in over the expired alice, then refreshes
    /// - Then:
    ///    - the session is bob's, and nothing is logged under the category
    func testOwnSignInOverAnotherUser_logsNothing() async throws {
        let client = try await restoredClient(holding: user("alice"))
        live.cognito.once("GetTokensFromRefreshToken") { (_: GetTokensFromRefreshTokenInput) -> GetTokensFromRefreshTokenOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Refresh Token has been revoked")
        }
        await refresh(client)
        let expired = try await client.fetchAuthSession()
        guard case .failure(.sessionExpired) = expired.userPoolTokensResult else {
            return XCTFail("alice's refresh token should be dead, got \(expired.userPoolTokensResult)")
        }

        live.scriptSRP("bob")
        let signedIn = try await client.signIn(username: "bob", password: "password")
        await refresh(client)

        XCTAssertEqual(signedIn.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(sink.lines, [])
    }

    /// Named sessions are literally unchanged: their record I/O has no observer, so a read never hops to the warning.
    ///
    /// - Given: a `.default` client and a named one
    /// - When: each core's record I/O is built
    /// - Then:
    ///    - only `.default`'s has an observer
    func testOnlyTheDefaultSessionsIOObservesReads() throws {
        let defaultClient = try makeClient()
        let named = try makeClient(work)

        XCTAssertNotNil(defaultClient.core.recordIO().observeRead)
        XCTAssertNil(named.core.recordIO().observeRead)
    }

    /// Only `.default` shares a record with the plugin: a named session's record changing user is not warned of.
    ///
    /// - Given: a named session signed in as alice
    /// - When:
    ///    - another writer stores bob in its record, and the client refreshes
    /// - Then:
    ///    - the session adopts bob, and nothing is logged under the category
    func testNamedSession_logsNothing() async throws {
        let client = try makeClient(work)
        live.scriptSRP("alice")
        let signedIn = try await client.signIn(username: "alice", password: "password")
        XCTAssertEqual(signedIn.nextStep, .done)
        let bob = try await userPayload("bob")
        guard case .record(let stored) = try harness.store().read(work) else {
            return XCTFail("the named session's record should read")
        }
        let written = try harness.store().write(
            SessionRecord(label: nil, username: "bob", userId: "sub-bob", kind: .userPoolAndIdentityPool, credentials: bob),
            for: work,
            expecting: stored.version
        )
        guard case .committed = written else {
            return XCTFail("the other writer's record should commit")
        }

        await refresh(client)

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "bob", userId: "sub-bob")))
        XCTAssertEqual(sink.lines, [])
    }

    // MARK: - Once per core

    /// - Given: `.default` restored as alice
    /// - When:
    ///    - the real plugin store saves bob, a guest, then carol, and the client refreshes several times after each
    ///    - then the core is released, a new one restores carol, and the plugin store saves dave
    /// - Then:
    ///    - the first core logs exactly one warning, and the new core exactly one more
    func testRepeatedChanges_logOncePerCore() async throws {
        var client: AmplifyCognitoClient? = try await restoredClient(holding: user("alice"))
        let changes = try await [user("bob"), guest("us-east-1:guest-1"), user("carol")]
        for next in changes {
            try pluginSaves(next)
            for _ in 1 ... 3 {
                try await refresh(XCTUnwrap(client))
            }
        }
        XCTAssertEqual(sink.lines.count, 1)
        client = nil
        await harness.waitForBaseline()

        client = try makeClient()
        _ = await client?.currentSessionState()
        try await pluginSaves(user("dave"))
        try await refresh(XCTUnwrap(client))
        try await refresh(XCTUnwrap(client))

        XCTAssertEqual(sink.lines.count, 2)
        XCTAssertEqual(Set(sink.lines.map(\.content)), [SessionCore.sharedRecordHoldsAnotherPrincipalWarning])
    }

    // MARK: - Helpers

    /// Exactly one line under the category, or with the warning's text: the warning, at `warn`, under the category,
    /// with none of `identifiers` nor the session ID in it.
    private func assertOneWarning(naming identifiers: [String], file: StaticString = #filePath, line: UInt = #line) {
        let lines = sink.lines
        XCTAssertEqual(lines.count, 1, "\(lines)", file: file, line: line)
        guard let logged = lines.first else {
            return
        }
        XCTAssertEqual(logged.content, SessionCore.sharedRecordHoldsAnotherPrincipalWarning, file: file, line: line)
        XCTAssertEqual(
            logged.content,
            "The default session's saved login now holds a different user or a guest than this client held. The Auth plugin may be running beside this client over the default session, which is not supported.",
            file: file,
            line: line
        )
        XCTAssertEqual(logged.level, .warn, file: file, line: line)
        XCTAssertEqual(logged.name, Self.category, file: file, line: line)
        for identifier in identifiers + [SessionID.default.stringValue, "amplify."] {
            XCTAssertFalse(logged.content.contains(identifier), "The warning names \(identifier)", file: file, line: line)
        }
    }

    /// A `.default` client whose core has restored `credentials`, saved by the plugin's store.
    private func restoredClient(holding credentials: AmplifyCredentials) async throws -> AmplifyCognitoClient {
        try pluginSaves(credentials)
        let client = try makeClient()
        _ = await client.currentSessionState()
        return client
    }

    private func pluginSaves(_ credentials: AmplifyCredentials) throws {
        try pluginStore().saveCredential(credentials)
    }

    /// What the plugin's store retrieves now.
    private func storedCredentials() throws -> AmplifyCredentials {
        try pluginStore().retrieveCredential()
    }

    /// A forced refresh: it re-reads the record under the gate first, whatever the credentials' expiry.
    private func refresh(_ client: AmplifyCognitoClient) async {
        _ = try? await client.fetchAuthSession(options: .init(forceRefresh: true))
    }

    /// `GetTokensFromRefreshToken` answers tokens, one version on, for the user whose refresh token it is sent
    /// (`refresh-<username>-v<version>`), so a refresh never changes the user.
    private func scriptRefreshKeepingTheUser() {
        live.cognito.always("GetTokensFromRefreshToken") { (input: GetTokensFromRefreshTokenInput) in
            let parts = (input.refreshToken ?? "").split(separator: "-")
            let username = parts.count > 1 ? String(parts[1]) : "unknown"
            let version = parts.last.flatMap { Int($0.dropFirst()) } ?? 1
            return GetTokensFromRefreshTokenOutput(authenticationResult: LiveEngineFixtures.tokens(username, version: version + 1))
        }
    }

    /// `username` signed in with both pools, through the live engine, as its payload.
    private func userPayload(_ username: String) async throws -> Data {
        try await live.signedInPayload(username, on: live.engine())
    }

    /// `username` signed in with both pools, through the live engine.
    private func user(_ username: String) async throws -> AmplifyCredentials {
        try await AmplifyCredentials.decoded(userPayload(username))
    }

    private func guest(_ identityId: String, version: Int = 1) -> AmplifyCredentials {
        .identityPoolOnly(identityID: identityId, credentials: Self.awsCredentials(version: version))
    }

    private func federated(_ identityId: String, version: Int = 1) -> AmplifyCredentials {
        .identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: identityId,
            credentials: Self.awsCredentials(version: version)
        )
    }

    private static func awsCredentials(version: Int) -> EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "AKID-v\(version)",
            secretAccessKey: "secret-v\(version)",
            sessionToken: "session-v\(version)",
            expiration: Date(timeIntervalSince1970: 4_000_000_000)
        )
    }

    /// The plugin's own credential store over the harness's keychain, with the client's configuration.
    private func pluginStore() -> AWSCognitoAuthCredentialStore {
        Self.pluginStore(over: pluginKeychain)
    }

    private var pluginKeychain: any KeychainItemStoreBehavior {
        harness.keychain.itemStore(service: SessionRecordStore.unsharedService)
    }

    private static func pluginStore(over keychain: any KeychainItemStoreBehavior) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: ClientFixtures.configuration),
            keychain: keychain,
            logger: DiscardingEngineLogger()
        )
    }

    /// The harness's dependencies, with the live engine over scripted Cognito in place of the fake engine.
    private var dependencies: SessionCoreDependencies {
        let base = harness.dependencies
        let live = live!
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try live.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: base.now
        )
        dependencies.makePreviousConfigurationRevoker = base.makePreviousConfigurationRevoker
        #if os(iOS) || os(macOS) || os(visionOS)
        dependencies.sheetLock = base.sheetLock
        #endif
        return dependencies
    }

    private func makeClient(_ sessionId: SessionID = .default) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: sessionId),
            dependencies: dependencies
        )
    }
}

/// Records every line logged under `AmplifyCognitoClient.DefaultSession`, or with the warning's text under any
/// category, while it is registered.
final class SharedRecordWarningCapture: LogSinkBehavior, @unchecked Sendable {

    struct Line: Equatable {
        let level: LogLevel
        let name: String
        let content: String
    }

    let id = UUID().uuidString

    // `@unchecked Sendable`: `captured` is only touched while holding `lock`.
    private let lock = NSLock()
    private var captured: [Line] = []

    var lines: [Line] {
        lock.withLock { captured }
    }

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        guard message.name == "AmplifyCognitoClient.DefaultSession"
            || message.content == SessionCore.sharedRecordHoldsAnotherPrincipalWarning else {
            return
        }
        let line = Line(level: message.level, name: message.name, content: message.content)
        lock.withLock { captured.append(line) }
    }
}
