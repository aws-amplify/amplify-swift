//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AWSCognitoAuthPlugin
import Foundation
import Security
import XCTest

/// The plugin, in the same app as the client, writes its record where the client's read-through of
/// `.default` looks for it. The adoption tests (AD-1, AD-2) build on this.
///
/// This target links `Amplify` and `AWSCognitoAuthPlugin`; `CognitoClientIntegrationTests` does not,
/// so that target stays a standing proof that the client needs neither.
final class PluginRecordLocationTests: XCTestCase {

    /// The plugin's record for the default backend's namespace. It is also the client's read-through record for
    /// `.default`, and this bundle shares the keychain with `CognitoClientIntegrationTests`, so it is
    /// removed before and after each test.
    private var legacyAccount = ""
    /// The test's own user, deleted at teardown.
    private var user: InteropUser?

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        let configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.outputsBundle()
        )
        legacyAccount = SessionRecordKey.legacySessionAccount(in: configuration.poolNamespace)
        try InteropEnvironment.deleteSessionAccount(legacyAccount)
        XCTAssertFalse(try InteropEnvironment.sessionAccounts().contains(legacyAccount), "setUp left \(RealKeychain.redact(legacyAccount))")
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(InteropEnvironment.outputsData()))
    }

    /// Removes the plugin's record first, whatever failed, then signs out only when Auth is configured:
    /// a throwing `setUp` leaves it unconfigured, and an unconfigured `Amplify.Auth` aborts the process.
    override func tearDown() async throws {
        if !legacyAccount.isEmpty {
            try? InteropEnvironment.deleteSessionAccount(legacyAccount)
        }
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        if let user {
            await InteropEnvironment.deleteFreshUser(user)
        }
        if !legacyAccount.isEmpty {
            try InteropEnvironment.deleteSessionAccount(legacyAccount)
        }
        try await super.tearDown()
    }

    /// The plugin's sign-in writes its record under the legacy key the client reads through, and no v1 record.
    ///
    /// - Given: The plugin configured from the default backend's outputs, the client configuration from the
    ///   same file, no plugin record for that namespace (`setUp` removes any left by an earlier run), and a
    ///   fresh user of the test's own
    /// - When:
    ///    - The user signs in through the plugin (SRP, its default)
    ///    - The plugin then signs out
    /// - Then:
    ///    - The sign-in completes, and the session service now holds
    ///      `SessionRecordKey.legacySessionAccount(in:)` for the client's namespace:
    ///      `amplify.<userPoolId>.<identityPoolId>.session`
    ///    - The plugin wrote no `amplify.1.` account (it never writes a v1 record)
    ///    - After the sign-out, the plugin reports signed out
    ///
    func testPluginWritesItsRecordUnderTheKeyTheClientReadsThrough() async throws {
        let user = try await InteropEnvironment.signUpFreshUser()
        self.user = user
        let v1Before = try InteropEnvironment.sessionAccounts().filter { $0.hasPrefix("amplify.1.") }

        let result = try await Amplify.Auth.signIn(username: user.username, password: user.password)

        XCTAssertTrue(result.isSignedIn)
        let accounts = try InteropEnvironment.sessionAccounts()
        XCTAssertTrue(accounts.contains(legacyAccount), RealKeychain.redact("No \(legacyAccount) in \(accounts)"))
        XCTAssertEqual(accounts.filter { $0.hasPrefix("amplify.1.") }, v1Before)

        _ = await Amplify.Auth.signOut()
        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn)
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

    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }

    /// The bundle to load `outputsResource` from: the test bundle, or the Gen2 translation of the Gen1 file.
    static func outputsBundle() throws -> Bundle {
        try requireProvisioned()
        return try PluginTestConfiguration.outputsBundle(outputsResource, in: bundle)
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

    /// A user of the test's own on the default backend, never one another run could be using: a `ccit-`
    /// username, an `@example.com` email (RFC 2606, never delivered to) and a password meeting the backend's
    /// policy, signed up through the client on a session used for nothing else, which is purged at once.
    /// The backend's pre-sign-up trigger confirms it. Delete it with `deleteFreshUser(_:)`.
    static func signUpFreshUser() async throws -> InteropUser {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let user = InteropUser(username: "ccit-\(hex)", password: "Ccit-\(UUID().uuidString)-1!")
        let configuration = try AuthClientConfiguration(from: outputsResource, bundle: outputsBundle())
        let sessionId = try SessionID.named("interop-signup-\(hex.prefix(8))")
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            let result = try await client.signUp(
                username: user.username,
                password: user.password,
                options: .init(userAttributes: [AuthClientUserAttribute(.email, value: "\(user.username)@example.com")])
            )
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
        guard let configuration = try? AuthClientConfiguration(from: outputsResource, bundle: outputsBundle()),
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

    private final class BundleToken {}
}

/// A fresh user's name and password. The password stays out of every textual representation.
struct InteropUser: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let username: String
    let password: String

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
