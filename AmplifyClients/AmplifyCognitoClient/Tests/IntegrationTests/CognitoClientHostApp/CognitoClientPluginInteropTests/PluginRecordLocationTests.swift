//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Foundation
import Security
import XCTest

/// The plugin, in the same app as the client, writes its record under its own key, `amplify.<ns>.session`, which is
/// also the client's `.default` session record. `PluginSharedLoginTests` (AD-1 … AD-8)
/// builds on this.
///
/// This target links `Amplify` and `AWSCognitoAuthPlugin`; `CognitoClientIntegrationTests` does not,
/// so that target stays a standing proof that the client needs neither.
final class PluginRecordLocationTests: XCTestCase {

    /// `.default`'s items for the default backend's namespace: the plugin's record, `amplify.<ns>.session`, which is
    /// `.default`'s session record, and the client's `$default.meta` sidecar and `$default.challenge` record beside
    /// it. This bundle shares the keychain with `CognitoClientIntegrationTests`, so all three are removed before
    /// and after each test.
    private var defaultAccounts: [String] = []
    /// The plugin's record, `amplify.<ns>.session`.
    private var pluginAccount = ""
    /// The client configuration for the default backend, from the same outputs as the plugin's.
    private var configuration: AuthClientConfiguration?
    /// The test's own user, deleted at teardown.
    private var user: InteropUser?

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        let configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        self.configuration = configuration
        pluginAccount = SessionRecordKey.pluginSessionAccount(in: configuration.poolNamespace)
        defaultAccounts = [
            pluginAccount,
            SessionRecordKey.metaAccount(in: configuration.poolNamespace),
            SessionRecordKey.account(for: .default, in: configuration.poolNamespace, kind: .challenge)
        ]
        try deleteDefaultAccounts()
        let left = try Set(InteropEnvironment.sessionAccounts()).intersection(defaultAccounts)
        XCTAssertTrue(left.isEmpty, "setUp left \(left.map(RealKeychain.redact))")
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(InteropEnvironment.outputsData()))
        // The test signs its user up through a client before the plugin's first call.
        try await InteropEnvironment.settlePlugin()
    }

    /// Removes `.default`'s items first, whatever failed, then signs out only when Auth is configured:
    /// a throwing `setUp` leaves it unconfigured, and an unconfigured `Amplify.Auth` aborts the process. Last, the
    /// user's device and advanced-security records and the plugin's `authConfiguration` go, so no later suite reads
    /// them.
    override func tearDown() async throws {
        try? deleteDefaultAccounts()
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        if let user {
            await InteropEnvironment.deleteFreshUser(user)
            if let configuration {
                try InteropEnvironment.removeDeviceRecords(of: user, under: configuration)
            }
        }
        try deleteDefaultAccounts()
        try InteropEnvironment.deleteSessionAccount(SessionRecordStore.pluginConfigurationAccount)
        try await super.tearDown()
    }

    /// The plugin's sign-in writes its record under its own key, `.default`'s session record, and no v1 record; its
    /// sign-out deletes it.
    ///
    /// - Given: The plugin configured from the default backend's outputs, the client configuration from the
    ///   same file, none of `.default`'s items for that namespace (`setUp` removes any left by an earlier run), and
    ///   a fresh user of the test's own
    /// - When:
    ///    - The user signs in through the plugin (SRP, its default)
    ///    - The plugin then signs out
    /// - Then:
    ///    - The sign-in completes, and the session service now holds
    ///      `SessionRecordKey.pluginSessionAccount(in:)` for the client's namespace:
    ///      `amplify.<userPoolId>.<identityPoolId>.session`
    ///    - The plugin wrote no `amplify.1.` account: it never writes a v1 record, nor `.default`'s sidecar
    ///    - Straight after the sign-out, before any fetch, its record is gone: the plugin deletes it, and writes
    ///      no signed-out marker
    ///    - A fetch then reports signed out. When it returns guest credentials (the default backend's identity pool
    ///      allows guests), it saves a guest record, `identityPoolOnly`, under the same key: `.default`'s record is
    ///      then the plugin's guest. When it returns none, it saves nothing
    ///
    func testPluginWritesItsRecordUnderTheDefaultSessionsKey() async throws {
        let user = try await InteropEnvironment.signUpFreshUser()
        self.user = user
        let v1Before = try InteropEnvironment.sessionAccounts().filter { $0.hasPrefix("amplify.1.") }

        let result = try await Amplify.Auth.signIn(username: user.username, password: user.password)

        XCTAssertTrue(result.isSignedIn)
        let accounts = try InteropEnvironment.sessionAccounts()
        XCTAssertTrue(accounts.contains(pluginAccount), RealKeychain.redact("No \(pluginAccount) in \(accounts)"))
        // A boolean, so a failure prints no account (accounts carry the pool identifiers).
        XCTAssertTrue(accounts.filter { $0.hasPrefix("amplify.1.") } == v1Before, "the plugin wrote a v1 account")

        _ = await Amplify.Auth.signOut()
        let afterSignOut = try InteropEnvironment.sessionAccounts()
        XCTAssertFalse(afterSignOut.contains(pluginAccount), "the plugin's record is left after the sign-out")

        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn)
        let afterFetch = RealKeychain.rows(service: SessionRecordStore.unsharedService).first { $0.account == pluginAccount }
        // Decided by what the fetch returned, not by the configuration: the Gen1 translation the plugin's CI uses
        // states no guest flag, and the plugin asks for guest credentials whenever there is an identity pool.
        let gotGuestCredentials = (try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()) != nil
        if gotGuestCredentials {
            let kind = afterFetch.map { PluginRecordSummary.peek(Data($0.value.utf8)).kind }
            XCTAssertTrue(kind == .guest, "the signed-out fetch got guest credentials but saved no guest record")
        } else {
            XCTAssertTrue(afterFetch == nil, "the signed-out fetch got no guest credentials but saved a record")
        }
    }

    private func deleteDefaultAccounts() throws {
        for account in defaultAccounts {
            try InteropEnvironment.deleteSessionAccount(account)
        }
    }
}

/// The interop target's test configuration, as in `CognitoClientIntegrationTests`' `IntegrationTestEnvironment`:
/// the plugin's default backend's outputs file, which the "Copy test configuration" build phase copies from
/// `$COGNITO_CLIENT_INTEG_DIR` (default `~/.aws-amplify/amplify-ios/testconfiguration`, where CI downloads it),
/// and the fresh users the tests sign in. Where only the plugin's Gen1 file for that backend was copied (as on
/// the plugin's CI), its Gen2 translation (`PluginTestConfiguration`) is what both the client and the plugin are
/// configured with, so both see the same pools.
enum InteropEnvironment {
    static let outputsResource = "AWSCognitoAuthPluginIntegrationTests-amplify_outputs"
    /// The client's own role beside the plugin's default one (the client suite's `SandboxPool.extended`): on CI,
    /// `infra/ci`'s `ccit-ci-default`, which holds the rotation client. Optional; copied when it is there.
    static let extendedOutputsResource = "AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs"

    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }

    /// The bundle to load `resource` (default: `outputsResource`) from: the test bundle, or the Gen2 translation
    /// of the Gen1 file.
    static func outputsBundle(_ resource: String = outputsResource) throws -> Bundle {
        try requireProvisioned()
        return try PluginTestConfiguration.outputsBundle(resource, in: bundle)
    }

    /// The Gen2 outputs document `outputsBundle()` holds, for `Amplify.configure(with: .data(_:))`.
    static func outputsData() throws -> Data {
        try requireProvisioned()
        return try PluginTestConfiguration.outputsData(outputsResource, in: bundle)
    }

    static func requireProvisioned() throws {
        guard PluginTestConfiguration.isPresent(outputsResource, in: bundle) else {
            throw InteropError("""
            \(outputsResource).json (or its Gen1 \(PluginTestConfiguration.gen1Resource(for: outputsResource) ?? "")\
            .json) is not in the test bundle. The build phase copies the plugin's test \
            configuration from $COGNITO_CLIENT_INTEG_DIR (default ~/.aws-amplify/amplify-ios/testconfiguration, \
            where CI downloads it). For a local run, write it with \
            AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/infra/plugin-configs.py --dir <dir>, then \
            rebuild with COGNITO_CLIENT_INTEG_DIR=<dir>.
            """)
        }
    }

    /// Why a sign-up on the sandbox fails fast while its self sign-up is off, its resting state, as
    /// `SandboxSignUp.selfSignUpOffMessage` says it in the client suite.
    static let selfSignUpOffMessage = """
    Self sign-up is off on the sandbox. Run the suite through infra/self-sign-up.sh on -- <command>.
    """

    /// Whether the outputs are the sandbox's: `infra/plugin-configs.py --dir` marks each file it writes with
    /// `custom.amplify_cognito_client_integ.sandbox: true`, as `IntegrationTestEnvironment.isSandbox(_:)` reads it.
    static var isSandbox: Bool {
        guard let data = try? outputsData(),
              let document = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let custom = document["custom"] as? [String: Any],
              let marker = custom["amplify_cognito_client_integ"] as? [String: Any] else {
            return false
        }
        return marker["sandbox"] as? Bool == true
    }

    /// Fails, before any request, a sign-up on the sandbox outside an `infra/self-sign-up.sh` run, which sets
    /// `COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on` (`TEST_RUNNER_…` to `xcodebuild`). The plugin's backends (CI) are
    /// never checked: they allow self sign-up, and the script never runs there.
    static func requireSelfSignUp() throws {
        guard isSandbox, ProcessInfo.processInfo.environment["COGNITO_CLIENT_INTEG_SELF_SIGN_UP"] != "on" else {
            return
        }
        throw InteropError(selfSignUpOffMessage)
    }

    /// A user of the test's own on the default backend, never one another run could be using: a `ccit-`
    /// username, an `@example.com` email (RFC 2606, never delivered to) and a password meeting the backend's
    /// policy, signed up through the client on a session used for nothing else, which is purged at once.
    /// The backend's pre-sign-up trigger confirms it. Signed up through `resource` (default: the default backend's
    /// outputs), which the user records. Delete it with `deleteFreshUser(_:)`.
    static func signUpFreshUser(through resource: String = outputsResource) async throws -> InteropUser {
        try requireSelfSignUp()
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let user = InteropUser(username: "ccit-\(hex)", password: "Ccit-\(UUID().uuidString)-1!", outputsResource: resource)
        let configuration = try AuthClientConfiguration(from: resource, bundle: outputsBundle(resource))
        let sessionId = try SessionID.named("interop-signup-\(hex.prefix(8))")
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            let result: AuthClientSignUpResult
            do {
                result = try await client.signUp(
                    username: user.username,
                    password: user.password,
                    options: .init(userAttributes: [AuthClientUserAttribute(.email, value: "\(user.username)@example.com")])
                )
            } catch AuthClientError.notAuthorized(let description, _, _)
                where description.contains("SignUp is not permitted") && isSandbox {
                // Inside a run, the run had turned it on, so something turned it off again since.
                if ProcessInfo.processInfo.environment["COGNITO_CLIENT_INTEG_SELF_SIGN_UP"] == "on" {
                    throw InteropError("""
                    Self sign-up was turned off on the sandbox during this infra/self-sign-up.sh run, which had \
                    turned it on (Cognito refused the sign-up: SignUp is not permitted). Check the account's \
                    security findings, then run the suite again.
                    """)
                }
                throw InteropError("\(selfSignUpOffMessage) (Cognito refused the sign-up: SignUp is not permitted.)")
            }
            guard result.isSignUpComplete else {
                throw InteropError("The backend did not confirm the fresh user: it needs a pre-sign-up trigger that does.")
            }
        }
        try await waitUntilReleased(sessionId)
        try await AmplifyCognitoClient.purgeStoredSession(sessionId: sessionId, configuration: configuration)
        return user
    }

    /// Deletes a user `signUpFreshUser()` made: it signs in through the client on a session used for nothing
    /// else and calls `deleteUser()`, and the session is purged. Best effort, for teardown: a user already
    /// gone is fine. Never touches the plugin's record.
    static func deleteFreshUser(_ user: InteropUser) async {
        guard let configuration = try? AuthClientConfiguration(
            from: user.outputsResource,
            bundle: outputsBundle(user.outputsResource)
        ),
              let sessionId = try? SessionID.named("interop-cleanup-\(UUID().uuidString.prefix(8).lowercased())") else {
            return
        }
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            if case .done = try await client.signIn(username: user.username, password: user.password).nextStep {
                try await client.deleteUser()
            }
        } catch {
            // Already gone, or left for the sandbox's cleanup of day-old test users.
        }
        try? await waitUntilReleased(sessionId)
        try? await AmplifyCognitoClient.purgeStoredSession(sessionId: sessionId, configuration: configuration)
    }

    /// Deletes `account` from the session service, in every entitled group. Absent is fine.
    static func deleteSessionAccount(_ account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SessionRecordStore.unsharedService,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw InteropError(RealKeychain.redact("Deleting \(account) returned \(status)."))
        }
    }

    /// Removes `user`'s device and advanced-security records under `configuration`'s pools from this device's
    /// keychain, as `DeviceTestCase` does: the plugin and the client keep them per user and never remove them.
    static func removeDeviceRecords(of user: InteropUser, under configuration: AuthClientConfiguration) throws {
        let store = DeviceRecordStore(namespace: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        try store.removeDeviceMetadata(for: user.username)
        try store.removeASFDeviceId(for: user.username)
    }

    /// Every account in the service the plugin and the client store session records under, sorted.
    static func sessionAccounts() throws -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SessionRecordStore.unsharedService,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess, let rows = result as? [[String: Any]] else {
            throw InteropError("Listing \(SessionRecordStore.unsharedService) returned \(status).")
        }
        return rows.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
    }

    /// Waits until the registry holds no live session for `sessionId`, as the client target's
    /// `SessionCleanup.waitUntilReleased` does. The bound only stops a leaked handle from hanging the run.
    static func waitUntilReleased(_ sessionId: SessionID, timeout: TimeInterval = 10) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while SessionCoreRegistry.shared.liveSession(for: sessionId) != nil {
            guard Date() < deadline else {
                throw InteropError("Session \(sessionId) was not released; is a client still held?")
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    /// Waits until the plugin `Amplify.configure` just configured has settled: it has built its credential store,
    /// which writes the `authConfiguration` item, and loaded its session. Call it after every configure that a
    /// client on `.default` follows.
    ///
    /// The plugin builds its credential store after `configure` returns, and a client's `.default` restore writes
    /// the same `authConfiguration` item, so without this the two race for it. Running the plugin and a client
    /// side by side is not supported (D-i), and a test must not rely on it.
    ///
    /// `getCurrentUser()` waits for the plugin to be configured, as every plugin call does, and then only reads.
    /// It throws `signedOut` when no one is signed in, which is ignored. Not `fetchAuthSession()`: signed out, on
    /// the default backend (whose identity pool allows guests) it fetches guest credentials and saves a guest record.
    ///
    /// Bounded: a plugin that never finishes configuring fails the test after `timeout` instead of hanging the run.
    /// The call is not structured under the timer, so a call that ignores cancellation cannot hold the wait open.
    static func settlePlugin(timeout: TimeInterval = 60) async throws {
        let gate = SettleGate()
        let call = Task {
            _ = try? await Amplify.Auth.getCurrentUser()
            gate.finish(settled: true)
        }
        let timer = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            gate.finish(settled: false)
        }
        let settled = await gate.wait()
        timer.cancel()
        guard settled else {
            call.cancel()
            throw InteropError("""
            The plugin did not finish configuring within \(Int(timeout)) s: Amplify.Auth.getCurrentUser() never \
            returned, so its credential store was never built.
            """)
        }
    }

    /// The first of `settlePlugin`'s call and timer to finish, waited for once.
    private final class SettleGate: @unchecked Sendable {
        private let lock = NSLock()
        private var result: Bool?
        private var waiter: CheckedContinuation<Bool, Never>?

        /// Records the first outcome and resumes the waiter, if one is waiting. Later outcomes are ignored.
        func finish(settled: Bool) {
            lock.lock()
            guard result == nil else {
                lock.unlock()
                return
            }
            result = settled
            let waiter = waiter
            self.waiter = nil
            lock.unlock()
            waiter?.resume(returning: settled)
        }

        /// The first outcome, waiting for it if neither has finished yet.
        func wait() async -> Bool {
            await withCheckedContinuation { continuation in
                lock.lock()
                if let result {
                    lock.unlock()
                    continuation.resume(returning: result)
                } else {
                    waiter = continuation
                    lock.unlock()
                }
            }
        }
    }

    private final class BundleToken {}
}

/// A fresh user's name and password. The password stays out of every textual representation.
struct InteropUser: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let username: String
    let password: String
    /// The outputs the user was signed up through, and is deleted through.
    var outputsResource: String = InteropEnvironment.outputsResource

    var description: String { "a fresh user" }
    var debugDescription: String { description }
    var customMirror: Mirror { Mirror(self, children: [:]) }
}

struct InteropError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
