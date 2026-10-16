//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A `.default` sign-out with nothing to sign out clears the AWSMobileClient logins (`DefaultSessionLegacyLoginTests`), so
/// it also retries a clear that failed on an earlier sign-out, as the plugin's sign-out from a signed-out state does; a
/// named session's never touches them.
final class DefaultSessionNoOpSignOutTests: XCTestCase {

    private var harness: ClientHarness!
    private let pools = StorageFixtures.pools
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: pools) }

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: alice signed in on `.default`, AWSMobileClient logins, and a first clear that fails
    /// - When: she signs out, then the app signs `.default` out again
    /// - Then:
    ///    - the first sign-out is `.complete` and leaves the logins, logging one warning per service; the second, with
    ///      nothing to sign out, clears them
    func testASignOutRetriesAClearThatFailed() async throws {
        harness.keychain.put(FakePayload.signedIn("alice").data, pluginAccount)
        seedLegacyLogins()
        let failing = FailingSwitch()
        let client = try defaultClient(dependencies: dependencies(failingWhile: failing))
        _ = await client.currentSessionState()
        let sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
        defer { AmplifyLogging.removeSink(sink) }

        failing.isOn = true
        let first = await client.signOut()
        failing.isOn = false

        XCTAssertEqual(first, .complete)
        XCTAssertEqual(harness.keychain.value(pluginAccount), PluginRecordFixtures.noCredentials)
        assertLegacyLogins(present: true, "after the failed clear")
        XCTAssertEqual(
            sink.lines(in: [ClientLog.category(ClientLog.sessionRecordStore)]),
            Array(repeating: SessionRecordStore.legacyLoginClearFailedWarning, count: services.count)
        )

        let second = await client.signOut()

        XCTAssertEqual(second, .complete)
        assertLegacyLogins(present: false, "after the retry")
    }

    /// - Given: a named session with no saved login, and AWSMobileClient logins
    /// - When: the client signs it out
    /// - Then:
    ///    - the result is `.complete`, and the AWSMobileClient logins are left: a named session is not the plugin's login
    func testANamedSessionsNoOpSignOutLeavesThem() async throws {
        seedLegacyLogins()
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies()
        )
        _ = await client.currentSessionState()

        let result = await client.signOut()

        XCTAssertEqual(result, .complete)
        assertLegacyLogins(present: true)
    }

    // MARK: Helpers

    /// Whether the AWSMobileClient stores' clear fails.
    private final class FailingSwitch: @unchecked Sendable {
        private let lock = NSLock()
        private var value = false
        var isOn: Bool {
            get { lock.withLock { value } }
            set { lock.withLock { value = newValue } }
        }
    }

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

    private func defaultClient(dependencies: SessionCoreDependencies) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: .default),
            dependencies: dependencies
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
    private func dependencies(failingWhile failing: FailingSwitch? = nil) -> SessionCoreDependencies {
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
