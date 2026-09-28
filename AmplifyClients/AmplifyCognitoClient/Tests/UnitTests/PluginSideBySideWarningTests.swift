//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The Auth plugin and the client side by side over the default session is not supported, and
/// `.default` ignores the plugin's record once it has its own. When it restores its own record while the plugin's
/// holds a different signed-in principal, it logs one warning per core, and changes nothing.
final class PluginSideBySideWarningTests: XCTestCase {

    private var harness: ClientHarness!
    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools) }
    private var ownAccount: String { harness.store().sessionAccount(for: .default) }
    private let alice = AuthClientUser(username: "alice", userId: "sub-alice")
    private var warningsBefore = 0

    override func setUp() {
        harness = ClientHarness()
        warningsBefore = SideBySideWarningCapture.shared.count
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    private var warnings: Int {
        SideBySideWarningCapture.shared.count - warningsBefore
    }

    /// Waits, bounded, for the core's check of the plugin's record, if it started one: it runs after the restore,
    /// detached.
    private func settled(_ client: AmplifyCognitoClient?, file: StaticString = #filePath, line: UInt = #line) async {
        await settlePluginPrincipalCheck(of: client, file: file, line: line)
    }

    private var pluginReads: Int {
        harness.keychain.readAccounts.count(where: { $0 == pluginAccount })
    }

    /// Stores `.default`'s own record for `own` and the plugin's record, then clears the keychain logs.
    private func given(own: FakePayload, plugin: Data?) throws -> (own: Data, plugin: Data?) {
        try harness.signIn(.default, own)
        if let plugin {
            harness.keychain.put(plugin, pluginAccount)
        }
        harness.keychain.resetLogs()
        return (try XCTUnwrap(harness.keychain.value(ownAccount)), plugin)
    }

    private func assertNothingWritten(_ stored: (own: Data, plugin: Data?), file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(harness.keychain.value(ownAccount), stored.own, file: file, line: line)
        XCTAssertEqual(harness.keychain.value(pluginAccount), stored.plugin, file: file, line: line)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount), file: file, line: line)
        XCTAssertFalse(harness.keychain.removedAccounts.contains(pluginAccount), file: file, line: line)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(ownAccount), file: file, line: line)
        XCTAssertFalse(harness.keychain.removedAccounts.contains(ownAccount), file: file, line: line)
    }

    // MARK: Warns

    /// - Given: `.default`'s own record for alice, and the plugin's record for bob
    /// - When:
    ///    - `.default` restores and reports its state
    /// - Then:
    ///    - it is signed in as alice, from its own record
    ///    - one warning is logged, at warning level, under the client's category, naming no one
    ///    - the plugin's key is read once, and neither record is written or deleted
    ///
    func testDifferentUser_logsOneWarning_andChangesNothing() async throws {
        let stored = try given(own: .signedIn("alice"), plugin: FakePayload.signedIn("bob").data)
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(warnings, 1)
        let logged = try XCTUnwrap(SideBySideWarningCapture.shared.last)
        XCTAssertEqual(logged.level, .warn)
        XCTAssertEqual(logged.name, ClientEngineLogger.category)
        for identifier in ["alice", "bob", "sub-", "$default", "amplify."] {
            XCTAssertFalse(logged.content.contains(identifier), "The warning names \(identifier)")
        }
        XCTAssertEqual(pluginReads, 1)
        assertNothingWritten(stored)
    }

    /// - Given: `.default`'s own guest record, and the plugin's guest record for another identity
    /// - When:
    ///    - `.default` restores and reports its state
    /// - Then:
    ///    - it is a guest, from its own record, and one warning is logged
    ///
    func testDifferentGuestIdentity_logsOneWarning() async throws {
        let stored = try given(
            own: .guest(identityId: "us-east-1:own-guest"),
            plugin: FakePayload.guest(identityId: "us-east-1:plugin-guest").data
        )
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .guest)
        XCTAssertEqual(warnings, 1)
        assertNothingWritten(stored)
    }

    /// - Given: `.default`'s own record for alice, and the plugin's record for bob
    /// - When:
    ///    - the first restore fails, because `.default`'s own key cannot be read, and a later one succeeds
    ///    - then the session is used many times, through two handles on the same core
    /// - Then:
    ///    - exactly one warning is logged, and the plugin's key is read once
    ///
    func testWarningIsLoggedOnceAcrossRepeatedRestoresAndCalls() async throws {
        let stored = try given(
            own: .signedIn("alice", identityId: "us-east-1:alice"),
            plugin: FakePayload.signedIn("bob").data
        )
        harness.keychain.failingReads(of: ownAccount, with: errSecInteractionNotAllowed)
        let client = try harness.client(.default)
        let failed = await client.currentSessionState()
        XCTAssertEqual(failed, .unavailable(.locked))
        await settled(client)
        XCTAssertEqual(warnings, 0)
        harness.keychain.clearFailures()

        for _ in 1 ... 3 {
            let state = await client.currentSessionState()
            await settled(client)
            XCTAssertEqual(state, .signedIn(alice))
            _ = try await client.fetchAuthSession()
        }
        let second = try harness.client(.default)
        _ = await second.currentSessionState()
        _ = try await second.fetchAuthSession()
        await settled(second)

        XCTAssertEqual(warnings, 1)
        XCTAssertEqual(pluginReads, 1)
        assertNothingWritten(stored)
    }

    /// - Given: `.default`'s own guest record, then its own federated record, each beside the plugin's record for bob
    /// - When:
    ///    - `.default` restores and reports its state, each time on a new core
    /// - Then:
    ///    - each logs one warning: the plugin is signed in as a user the client's session is not
    ///    - neither record changes
    ///
    func testPluginUserBesideOwnGuestOrFederatedRecord_logsOneWarningEach() async throws {
        let plugin = FakePayload.signedIn("bob").data
        let owns: [(FakePayload, AuthSessionState)] = [
            (.guest(identityId: "us-east-1:own-guest"), .guest),
            (.federated(identityId: "us-east-1:own-federated"), .federated(identityId: "us-east-1:own-federated"))
        ]
        for (index, (own, expected)) in owns.enumerated() {
            try harness.store().purge(.default)
            let stored = try given(own: own, plugin: plugin)
            var client: AmplifyCognitoClient? = try harness.client(.default)

            let state = await client?.currentSessionState()
            await settled(client)

            XCTAssertEqual(state, expected)
            XCTAssertEqual(warnings, index + 1)
            assertNothingWritten(stored)
            client = nil
            await harness.waitForBaseline()
        }
    }

    /// The check runs after the restore, off its gate and flight: a plugin-key read that never returns neither delays
    /// nor fails it. Nothing here measures time: the restore is bounded, so a restore that waited for the stuck read
    /// would come back `.unavailable(.interrupted)`, and the stall is released only after every answer arrived.
    ///
    /// - Given: `.default`'s own record for alice, the plugin's record for bob whose read blocks until released, and a
    ///   short restore bound
    /// - When:
    ///    - `.default` restores and reports its state, then, while the plugin's read is still stuck, sets its label
    ///      (under the record's gate, on its I/O queue) and reports its state again
    ///    - then the read is released
    /// - Then:
    ///    - every answer is signed in as alice, and the label is written, while the read is stuck
    ///    - the warning is logged only once the read returns, and the plugin's record is unchanged
    ///
    func testStalledPluginRead_neitherDelaysNorFailsTheRestore() async throws {
        harness.setRestoreBound(nanoseconds: 200_000_000)
        let stored = try given(own: .signedIn("alice"), plugin: FakePayload.signedIn("bob").data)
        let stall = Stall()
        defer { stall.release() }
        harness.keychain.onceAfterReading(pluginAccount) { stall.block() }
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await waitUntil("the plugin's read is stuck") { stall.hasBeenReached }
        try await client.setSessionLabel("Home")
        let again = await client.currentSessionState()

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(again, .signedIn(alice))
        XCTAssertEqual(try harness.storedRecord(.default)?.label, "Home")
        XCTAssertEqual(warnings, 0)
        stall.release()
        await settled(client)
        XCTAssertEqual(warnings, 1)
        XCTAssertEqual(harness.keychain.value(pluginAccount), stored.plugin)
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(pluginAccount))
        XCTAssertFalse(harness.keychain.removedAccounts.contains(pluginAccount))
    }

    // MARK: Stays quiet

    /// - Given: `.default`'s own record for alice, and the plugin's record for alice with newer tokens (the plugin
    ///   refreshed the same user)
    /// - When:
    ///    - `.default` restores and reports its state
    /// - Then:
    ///    - no warning is logged, and neither record changes
    ///
    func testSameUser_logsNothing() async throws {
        let stored = try given(own: .signedIn("alice"), plugin: FakePayload.signedIn("alice", version: 2).data)
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(warnings, 0)
        assertNothingWritten(stored)
    }

    /// - Given: `.default`'s own record for alice, and the plugin's record for a guest (the plugin signed its user
    ///   out and is now unauthenticated)
    /// - When:
    ///    - `.default` restores and reports its state
    /// - Then:
    ///    - no warning is logged: the plugin is not signed in as another user
    ///
    func testPluginGuestBesideOwnUser_logsNothing() async throws {
        let stored = try given(own: .signedIn("alice"), plugin: FakePayload.guest(identityId: "us-east-1:guest").data)
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(warnings, 0)
        assertNothingWritten(stored)
    }

    /// - Given: `.default`'s own record for alice, and the plugin's signed-out marker, then no plugin record at all
    /// - When:
    ///    - `.default` restores and reports its state, each time on a new core
    /// - Then:
    ///    - no warning is logged, and neither record changes
    ///
    func testPluginSignedOutOrAbsent_logsNothing() async throws {
        let marker = Data(#"{"noCredentials":{}}"#.utf8)
        let stored = try given(own: .signedIn("alice"), plugin: nil)
        for plugin in [marker, nil] {
            if let plugin {
                harness.keychain.put(plugin, pluginAccount)
            } else {
                try harness.store().removePluginRecord(for: .default)
            }
            harness.keychain.resetLogs()
            var client: AmplifyCognitoClient? = try harness.client(.default)

            let state = await client?.currentSessionState()
            await settled(client)

            XCTAssertEqual(state, .signedIn(alice))
            XCTAssertEqual(warnings, 0)
            assertNothingWritten((stored.own, plugin))
            client = nil
            await harness.waitForBaseline()
        }
    }

    /// - Given: `.default`'s own signed-out row, and the plugin's record for bob
    /// - When:
    ///    - `.default` restores and reports its state
    /// - Then:
    ///    - it is signed out, no warning is logged, and the plugin's key is not read
    ///
    func testOwnRecordSignedOut_logsNothing_andDoesNotReadThePluginRecord() async throws {
        XCTAssertTrue(try harness.store().write(.signedOut(label: nil, username: "alice"), for: .default, expecting: nil).didCommit)
        harness.keychain.put(FakePayload.signedIn("bob").data, pluginAccount)
        harness.keychain.resetLogs()
        let client = try harness.client(.default)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(warnings, 0)
        XCTAssertEqual(pluginReads, 0)
    }

    /// - Given: `.default`'s own record for alice, and a plugin record whose key cannot be read, then one whose bytes
    ///   cannot be described
    /// - When:
    ///    - `.default` restores and reports its state, each time on a new core
    /// - Then:
    ///    - the restore succeeds, signed in as alice, no warning is logged, and neither record changes
    ///
    func testPluginRecordUnreadable_logsNothing_andTheRestoreSucceeds() async throws {
        let stored = try given(own: .signedIn("alice"), plugin: nil)
        for undescribable in [false, true] {
            let plugin = undescribable ? Data("not a record".utf8) : FakePayload.signedIn("bob").data
            harness.keychain.put(plugin, pluginAccount)
            if !undescribable {
                harness.keychain.failingReads(of: pluginAccount, with: errSecInteractionNotAllowed)
            }
            harness.keychain.resetLogs()
            var client: AmplifyCognitoClient? = try harness.client(.default)

            let state = await client?.currentSessionState()
            await settled(client)
            let session = try await XCTUnwrap(client).fetchAuthSession()

            XCTAssertEqual(state, .signedIn(alice))
            XCTAssertEqual(try session.userSubResult.get(), "sub-alice")
            XCTAssertEqual(warnings, 0)
            XCTAssertEqual(pluginReads, 1)
            harness.keychain.clearFailures()
            assertNothingWritten((stored.own, plugin))
            client = nil
            await harness.waitForBaseline()
        }
    }

    /// - Given: a named session's record for alice, and the plugin's record for bob
    /// - When:
    ///    - the named session restores and reports its state
    /// - Then:
    ///    - no warning is logged, and the plugin's key is not read: only `.default` ever looks at it
    ///
    func testNamedSession_logsNothing_andDoesNotReadThePluginRecord() async throws {
        let work = ClientFixtures.id("work")
        try harness.signIn(work, .signedIn("alice"))
        harness.keychain.put(FakePayload.signedIn("bob").data, pluginAccount)
        harness.keychain.resetLogs()
        let client = try harness.client(work)

        let state = await client.currentSessionState()
        await settled(client)

        XCTAssertEqual(state, .signedIn(alice))
        XCTAssertEqual(warnings, 0)
        XCTAssertEqual(pluginReads, 0)
    }

    // MARK: The comparison

    /// - Given: pairs of the plugin's and `.default`'s principals
    /// - When:
    ///    - each pair is compared
    /// - Then:
    ///    - only a provably different signed-in principal answers yes: another `sub` (else user name), a user beside a
    ///      guest or federated identity, or two user-less identities with different identity IDs
    ///
    func testIsProvablyAnotherPrincipal() {
        let alice = CredentialSummary(kind: .userPoolAndIdentityPool, username: "alice", userId: "sub-a")
        let aliceRenamed = CredentialSummary(kind: .userPoolOnly, username: "alice-2", userId: "sub-a")
        let bob = CredentialSummary(kind: .userPoolOnly, username: "bob", userId: "sub-b")
        let aliceNoSub = CredentialSummary(kind: .userPoolOnly, username: "alice", userId: nil)
        let bobNoSub = CredentialSummary(kind: .userPoolOnly, username: "bob", userId: nil)
        let guestA = CredentialSummary(kind: .guest, username: nil, userId: nil, identityId: "id-a")
        let guestB = CredentialSummary(kind: .guest, username: nil, userId: nil, identityId: "id-b")
        let federatedB = CredentialSummary(kind: .federated, username: nil, userId: nil, identityId: "id-b")
        let guestUnknown = CredentialSummary(kind: .guest, username: nil, userId: nil)
        let signedOut = CredentialSummary(kind: .signedOut, username: nil, userId: nil)

        let cases: [(plugin: CredentialSummary, own: CredentialSummary, expected: Bool, line: UInt)] = [
            (bob, alice, true, #line),
            (alice, alice, false, #line),
            (aliceRenamed, alice, false, #line),
            (bobNoSub, aliceNoSub, true, #line),
            (aliceNoSub, alice, false, #line),
            (bob, guestA, true, #line),
            (bob, federatedB, true, #line),
            (guestA, alice, false, #line),
            (guestA, guestB, true, #line),
            (guestA, federatedB, true, #line),
            (guestB, federatedB, false, #line),
            (guestA, guestA, false, #line),
            (guestUnknown, guestA, false, #line),
            (signedOut, alice, false, #line),
            (bob, signedOut, false, #line)
        ]
        for testCase in cases {
            XCTAssertEqual(testCase.plugin.isProvablyAnotherPrincipal(than: testCase.own), testCase.expected, line: testCase.line)
        }
    }
}

/// Captures the side-by-side warning from every logger in the process. Registered once, the first time a test asks for it, and
/// never removed: `AmplifyLogging.removeSink` is internal to AmplifyFoundation, which this target does not import
/// `@testable`. So each test counts the warnings logged since it began.
final class SideBySideWarningCapture: LogSinkBehavior, @unchecked Sendable {

    struct Captured: Equatable {
        let level: LogLevel
        let name: String
        let content: String
    }

    static let shared: SideBySideWarningCapture = {
        let sink = SideBySideWarningCapture()
        AmplifyLogging.addSink(sink)
        return sink
    }()

    let id = "PluginSideBySideWarningTests.capture"

    // `@unchecked Sendable`: `captured` is only touched while holding `lock`.
    private let lock = NSLock()
    private var captured: [Captured] = []

    var count: Int {
        lock.withLock { captured.count }
    }

    var last: Captured? {
        lock.withLock { captured.last }
    }

    func isEnabled(for logLevel: LogLevel) -> Bool {
        true
    }

    func emit(message: LogMessage) {
        guard message.content == SessionCore.pluginHoldsAnotherSessionWarning else {
            return
        }
        let entry = Captured(level: message.level, name: message.name, content: message.content)
        lock.withLock { captured.append(entry) }
    }
}
