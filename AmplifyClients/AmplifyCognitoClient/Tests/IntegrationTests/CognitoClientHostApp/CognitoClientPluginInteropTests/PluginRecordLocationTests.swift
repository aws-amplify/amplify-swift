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

    /// The plugin's record for the sandbox namespace. It is also the client's read-through record for
    /// `.default`, and this bundle shares the keychain with `CognitoClientIntegrationTests`, so it is
    /// removed before and after each test.
    private var legacyAccount = ""

    override func setUp() async throws {
        try await super.setUp()
        try InteropEnvironment.requireProvisioned()
        let configuration = try AuthClientConfiguration(
            from: InteropEnvironment.outputsResource,
            bundle: InteropEnvironment.bundle
        )
        legacyAccount = SessionRecordKey.legacySessionAccount(in: configuration.poolNamespace)
        try InteropEnvironment.deleteSessionAccount(legacyAccount)
        XCTAssertFalse(try InteropEnvironment.sessionAccounts().contains(legacyAccount), "setUp left \(RealKeychain.redact(legacyAccount))")
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(InteropEnvironment.data(forResource: InteropEnvironment.outputsResource)))
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
        if !legacyAccount.isEmpty {
            try InteropEnvironment.deleteSessionAccount(legacyAccount)
        }
        try await super.tearDown()
    }

    /// The plugin's sign-in writes its record under the legacy key the client reads through, and no v1 record.
    ///
    /// - Given: The plugin configured from the sandbox outputs, the client configuration from the same
    ///   file, and no plugin record for that namespace (`setUp` removes any left by an earlier run)
    /// - When:
    ///    - `alice` signs in through the plugin (SRP, its default)
    ///    - The plugin then signs out
    /// - Then:
    ///    - The sign-in completes, and the session service now holds
    ///      `SessionRecordKey.legacySessionAccount(in:)` for the client's namespace:
    ///      `amplify.<userPoolId>.<identityPoolId>.session`
    ///    - The plugin wrote no `amplify.1.` account (it never writes a v1 record)
    ///    - After the sign-out, the plugin reports signed out
    ///
    func testPluginWritesItsRecordUnderTheKeyTheClientReadsThrough() async throws {
        let v1Before = try InteropEnvironment.sessionAccounts().filter { $0.hasPrefix("amplify.1.") }

        let result = try await Amplify.Auth.signIn(username: "alice", password: InteropEnvironment.password(for: "alice"))

        XCTAssertTrue(result.isSignedIn)
        let accounts = try InteropEnvironment.sessionAccounts()
        XCTAssertTrue(accounts.contains(legacyAccount), RealKeychain.redact("No \(legacyAccount) in \(accounts)"))
        XCTAssertEqual(accounts.filter { $0.hasPrefix("amplify.1.") }, v1Before)

        _ = await Amplify.Auth.signOut()
        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn)
    }
}

/// The sandbox fixtures the "Copy sandbox configuration" phase copied into this bundle, as in
/// `CognitoClientIntegrationTests`' `IntegrationTestEnvironment`.
enum InteropEnvironment {
    static let outputsResource = "amplify_outputs"
    static let usersResource = "cognito-client-integ-users"

    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }

    static func requireProvisioned() throws {
        guard bundle.url(forResource: outputsResource, withExtension: "json") != nil else {
            throw InteropError("""
            \(outputsResource).json is not in the test bundle. Run \
            AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/infra/provision.sh, then rebuild.
            """)
        }
    }

    static func data(forResource resource: String) throws -> Data {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw InteropError("\(resource).json is not in the test bundle.")
        }
        return try Data(contentsOf: url)
    }

    /// A password from `users.json`. Never printed.
    static func password(for username: String) throws -> String {
        let fields = try JSONSerialization.jsonObject(with: data(forResource: usersResource)) as? [String: String]
        guard let password = fields?[username], !password.isEmpty else {
            throw InteropError("users.json has no \(username); re-run infra/provision.sh.")
        }
        return password
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

struct InteropError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
