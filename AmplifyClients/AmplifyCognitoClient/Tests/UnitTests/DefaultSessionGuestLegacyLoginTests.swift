//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A guest written over `.default`'s signed-out record clears the AWSMobileClient logins again first. The signed-out
/// record stops a plugin build from migrating a login whose clear failed at sign-out, but a guest counts as no session
/// there, so once the guest replaces it only the clear protects the user. Over an absent record nothing is cleared, nor
/// over a label alone: a client-only app that never signed in keeps those logins for a plugin build to migrate.
final class DefaultSessionGuestLegacyLoginTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let pools = StorageFixtures.pools
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: alice signed in on `.default`, AWSMobileClient logins left from an earlier release, and their clear
    ///   failing
    /// - When: she signs out, which leaves them; then, with the clear working, `.default`'s session is fetched, which
    ///   fetches a guest
    /// - Then:
    ///    - after the sign-out the record is signed out and the logins are still there
    ///    - after the fetch the record holds a guest, and the logins are gone, so a plugin build has nothing to migrate
    func testAGuestOverASignedOutRecordClearsWhatTheSignOutLeft() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        seedLegacyLogins()
        let failing = FailingSwitch(isOn: true)
        let client = try defaultClient(failingWhile: failing)
        _ = await client.currentSessionState()

        let result = await client.signOut()
        XCTAssertEqual(result, .complete, "\(result)")
        XCTAssertEqual(try harness.storedRecord(.default)?.isSignedOut, true)
        assertLegacyLogins(present: true, "after the sign-out whose clear failed")
        failing.isOn = false

        _ = try await client.fetchAuthSession()

        XCTAssertEqual(try harness.storedRecord(.default)?.kind, .guest)
        assertLegacyLogins(present: false, "after the guest")
    }

    /// - Given: `.default`'s record holding `{"noCredentials":{}}`, as a sign-out stopped between its signed-out write
    ///   and its clear left it, or a plugin sign-out under an access group whose clear failed, and AWSMobileClient
    ///   logins
    /// - When: `.default`'s session is fetched, which fetches a guest
    /// - Then:
    ///    - the record holds a guest, and the logins are gone
    func testAGuestOverThePluginsSignedOutRecordClearsThem() async throws {
        harness.keychain.put(PluginRecordFixtures.noCredentials, pluginAccount)
        seedLegacyLogins()
        let client = try defaultClient()

        _ = try await client.fetchAuthSession()

        XCTAssertEqual(try harness.storedRecord(.default)?.kind, .guest)
        assertLegacyLogins(present: false)
    }

    /// - Given: nothing saved under `.default`, as in a client-only app that never signed in, and AWSMobileClient logins
    /// - When: `.default`'s session is fetched, which fetches a guest
    /// - Then:
    ///    - the record holds a guest, and the logins are kept, for a plugin build to migrate: the client never
    ///      migrates them, and nobody signed out
    func testAGuestOverAnAbsentRecordKeepsThem() async throws {
        seedLegacyLogins()
        let client = try defaultClient()

        _ = try await client.fetchAuthSession()

        XCTAssertEqual(try harness.storedRecord(.default)?.kind, .guest)
        assertLegacyLogins(present: true)
    }

    /// A label alone is no record: it is the sidecar, which reads as a signed-out row, but the plugin's record is
    /// still absent.
    ///
    /// - Given: nothing saved under `.default`, then a label set on it before anyone signed in, and AWSMobileClient logins
    /// - When: `.default`'s session is fetched, which fetches a guest
    /// - Then:
    ///    - the label was written to the sidecar only, with no shared record
    ///    - the record holds a guest with that label, and the logins are kept, for a plugin build to migrate
    func testAGuestOverALabelAloneKeepsThem() async throws {
        seedLegacyLogins()
        let client = try defaultClient()
        try await client.setSessionLabel("Personal")
        XCTAssertNil(harness.keychain.value(pluginAccount), "a label should write the sidecar only")
        XCTAssertNotNil(harness.keychain.value(SessionRecordKey.metaAccount(in: pools)), "the label's sidecar")

        _ = try await client.fetchAuthSession()

        let stored = try harness.storedRecord(.default)
        XCTAssertEqual(stored?.kind, .guest)
        XCTAssertEqual(stored?.label, "Personal")
        assertLegacyLogins(present: true)
    }

    /// - Given: a named session's signed-out row, and AWSMobileClient logins
    /// - When: its session is fetched, which fetches a guest
    /// - Then:
    ///    - the row holds a guest, and the logins are kept: only `.default` is the plugin's saved login
    func testANamedSessionsGuestKeepsThem() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try client(work)
        let result = await client.signOut()
        XCTAssertEqual(result, .complete, "\(result)")
        seedLegacyLogins()

        _ = try await client.fetchAuthSession()

        XCTAssertEqual(try harness.storedRecord(work)?.kind, .guest)
        assertLegacyLogins(present: true)
    }

    // MARK: Helpers

    private var services: [String] {
        SessionRecordStore.legacyLoginServices(for: pools)
    }

    private func seedLegacyLogins() {
        for service in services {
            harness.keychain.put(Data("legacy".utf8), "tokens.alice", service: service)
        }
    }

    private func assertLegacyLogins(present: Bool, _ context: String = "", file: StaticString = #filePath, line: UInt = #line) {
        for service in services {
            let value = harness.keychain.value(service: service, account: "tokens.alice")
            XCTAssertEqual(value != nil, present, "\(service) \(context)", file: file, line: line)
        }
    }

    private func defaultClient(failingWhile failing: FailingSwitch? = nil) throws -> AmplifyCognitoClient {
        try client(.default, failingWhile: failing)
    }

    private func client(_ sessionId: SessionID, failingWhile failing: FailingSwitch? = nil) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: sessionId),
            dependencies: dependencies(failingWhile: failing)
        )
    }

    /// A store over the harness's keychain, as `TestKeychain.recordStore(for:)` builds it, that clears the harness's
    /// AWSMobileClient services, or fails to while `failing` is on.
    private static func store(
        over keychain: TestKeychain,
        for namespace: SessionStorageNamespace,
        failing: FailingSwitch?
    ) -> SessionRecordStore {
        let services = SessionRecordStore.legacyLoginServices(for: namespace.pools)
        let clock = TestClock()
        return SessionRecordStore(
            namespace: namespace,
            keychain: keychain.itemStore(
                service: SessionRecordStore.service(forAccessGroup: namespace.accessGroup),
                accessGroup: namespace.accessGroup
            ),
            now: { clock.next() },
            userPoolTokensOnly: TestKeychain.userPoolTokensOnly,
            identityIdOf: TestKeychain.identityId,
            refreshTokenOf: TestKeychain.refreshToken,
            markerScope: TestKeychain.markerScope,
            summarizeSharedRecord: TestKeychain.summarizeSharedRecord,
            rereadsAbsentSharedRecord: false,
            sameCredentials: TestKeychain.sameCredentials,
            legacyLoginStores: {
                if failing?.isOn == true {
                    return services.map { _ in UnclearableItemStore() }
                }
                return services.map { keychain.itemStore(service: $0) }
            }
        )
    }

    /// The harness's dependencies, with stores that clear the harness's AWSMobileClient services.
    private func dependencies(failingWhile failing: FailingSwitch?) -> SessionCoreDependencies {
        let base = harness.dependencies
        var dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: { [keychain = harness.keychain] in Self.store(over: keychain, for: $0, failing: failing) },
            makeClients: base.makeClients,
            makeEngine: base.makeEngine,
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
}

/// Whether the AWSMobileClient stores fail to clear: a test turns it off to let a later clear through.
private final class FailingSwitch: @unchecked Sendable {
    // `@unchecked Sendable`: `on` is only touched while holding `lock`.
    private let lock = NSLock()
    private var on: Bool

    init(isOn: Bool) {
        self.on = isOn
    }

    var isOn: Bool {
        get { lock.withLock { on } }
        set { lock.withLock { on = newValue } }
    }
}

/// An item store whose `removeAll` fails, and that holds nothing otherwise.
private struct UnclearableItemStore: KeychainItemStoreBehavior {
    func getData(_ key: String) throws -> Data { throw KeychainAccessError.itemNotFound }
    func set(_ value: Data, key: String) throws {}
    func addIfAbsent(_ value: Data, key: String) throws -> Bool { true }
    func replaceIfPresent(_ value: Data, key: String) throws -> Bool { false }
    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome { .notFound }
    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome { .notFound }
    func remove(_ key: String) throws {}
    func remove(_ entry: KeychainEntry) throws {}
    func removeAll() throws { throw KeychainAccessError.securityError(errSecInteractionNotAllowed) }
    func hasItems() throws -> Bool { false }
    func allAccounts() throws -> [String] { [] }
    func allEntries() throws -> [KeychainEntry] { [] }
}
