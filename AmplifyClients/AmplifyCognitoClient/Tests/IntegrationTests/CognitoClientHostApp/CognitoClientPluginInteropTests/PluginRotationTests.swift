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
import XCTest

/// Refresh-token rotation across the plugin and the client's `.default`, on live Cognito (RT-1, RT-2).
///
/// With rotation on, every refresh returns a new refresh token, and Cognito refuses the one it replaced with
/// `RefreshTokenReuseException`. Before the shared saved login the plugin and the client
/// each kept their own copy, so after one side rotated, the other (a rolled-back plugin, or the client rolling
/// forward) presented a dead token. With one shared saved login, each side reads the other's newest token: this is
/// the shared login's rollback claim, and these tests check it end to end.
///
/// They need the default pool's `rotation` app client (`infra/pools/default.json`: rotation on, no grace period,
/// so a reused token is refused at once), named in `AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json`,
/// which `infra/plugin-configs.py` writes once `infra/provision.sh` has made that client. Without the file they
/// skip on CI and on backends other than the sandbox, which have no such client, and fail on the sandbox, asking
/// for it to be provisioned.
///
/// Both sides use the rotation outputs. The fresh user is signed up through the outputs of the role that holds the
/// rotation client (`InteropEnvironment.rotationBaseResource`): the client's own extended role when its file is
/// there (on CI, `infra/ci`'s `ccit-ci-default`), else the default backend (the sandbox's). The rotation outputs must
/// name that role's user pool, so the user is the rotation client's. The plugin's keychain service is wiped before
/// and after each test, as the interop suite's other
/// keychain tests do. Tokens are compared with booleans and never printed.
final class PluginRotationTests: XCTestCase {

    static let outputsResource = "AmplifyCognitoClientRotationIntegrationTests-amplify_outputs"

    private var configuration: AuthClientConfiguration!
    private var outputsData = Data()
    /// The test's own user, signed up in `setUp` and deleted at teardown.
    private var alice: InteropUser?

    override func setUp() async throws {
        try await super.setUp()
        guard let url = InteropEnvironment.bundle.url(forResource: Self.outputsResource, withExtension: "json") else {
            try Self.skipOrFailWithoutTheRotationClient()
            return
        }
        outputsData = try Data(contentsOf: url)
        configuration = try AuthClientConfiguration(from: Self.outputsResource, bundle: InteropEnvironment.bundle)
        let baseResource = InteropEnvironment.rotationBaseResource
        let base = try AuthClientConfiguration(from: baseResource, bundle: InteropEnvironment.outputsBundle(baseResource))
        guard InteropEnvironment.signsUpOnTheRotationPool(
            rotationPoolId: configuration.userPool?.poolId,
            basePoolId: base.userPool?.poolId
        ) else {
            throw InteropError("""
            The rotation outputs name another user pool than \(baseResource).json's: the fresh user is signed up there.
            """)
        }
        RealKeychain.wipe(SessionRecordStore.unsharedService)
        alice = try await InteropEnvironment.signUpFreshUser(through: baseResource)
        try await configurePlugin()
    }

    /// Signs the plugin out (revoking the newest refresh token it holds), whatever failed, then deletes the user and
    /// its device records, and wipes the service. Signs out only when Auth is configured: an unconfigured
    /// `Amplify.Auth` aborts the process.
    override func tearDown() async throws {
        if Amplify.Auth.isConfigured {
            _ = await Amplify.Auth.signOut()
        }
        await Amplify.reset()
        try? await InteropEnvironment.waitUntilReleased(.default)
        if let alice {
            await InteropEnvironment.deleteFreshUser(alice)
        }
        RealKeychain.wipe(SessionRecordStore.unsharedService)
        alice = nil
        try await super.tearDown()
    }

    /// RT-1. The client rotates the refresh token, and a relaunched plugin refreshes with the rotated one.
    ///
    /// - Given: the plugin configured with the rotation outputs and nothing stored, and `alice` signed in through a
    ///   client on `.default` over the same outputs
    /// - When:
    ///    - the client force-refreshes, and is released
    ///    - the plugin is reset and configured again, as at a relaunch (or a rollback to a plugin-only build), and
    ///      force-refreshes
    /// - Then:
    ///    - the client's refresh rotated the refresh token: rotation is on
    ///    - the relaunched plugin holds the client's rotated token, and its refresh succeeds, rotating again: no
    ///      `RefreshTokenReuseException`, which a stale copy of the replaced token would get
    ///
    func testClientRotationIsUsedByARelaunchedPlugin() async throws {
        let fresh = try XCTUnwrap(alice)
        let rotated: String
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: .default))
            let signIn = try await client.signIn(username: fresh.username, password: fresh.password)
            guard case .done = signIn.nextStep else {
                return XCTFail("alice did not sign in through the client")
            }
            let first = try await client.fetchAuthSession().userPoolTokensResult.get().refreshToken
            let refreshed = try await client.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult
            guard case .success(let tokens) = refreshed else {
                return XCTFail("the client's refresh failed: \(Self.caseName(of: refreshed))")
            }
            XCTAssertTrue(tokens.refreshToken != first, "the client's refresh did not rotate the refresh token: is rotation on?")
            rotated = tokens.refreshToken
        }
        try await InteropEnvironment.waitUntilReleased(.default)

        try await relaunchPlugin()

        let held = try await pluginTokens()
        XCTAssertTrue((try? held.get().refreshToken) == rotated, "the relaunched plugin does not hold the client's rotated token")
        let refreshed = try await pluginTokens(forceRefresh: true)
        switch refreshed {
        case .success(let tokens):
            XCTAssertTrue(tokens.refreshToken != rotated, "the plugin's refresh did not rotate the token again")
        case .failure(let error):
            XCTFail("the relaunched plugin's refresh failed: \(Self.describe(error))")
        }
    }

    /// RT-2. The plugin rotates the refresh token, and the client's `.default` restores and refreshes with the
    /// rotated one; a plugin relaunched after that reads the client's.
    ///
    /// - Given: the plugin configured with the rotation outputs, and `alice` signed in through it
    /// - When:
    ///    - the plugin force-refreshes
    ///    - a client on `.default` over the same outputs restores, then force-refreshes, and is released
    ///    - the plugin is reset and configured again, and force-refreshes
    /// - Then:
    ///    - the plugin's refresh rotated the refresh token
    ///    - the client restored `.signedIn(alice)` holding the plugin's rotated token, and its refresh succeeded,
    ///      rotating again, with no `sessionExpired`; it stays signed in
    ///    - the relaunched plugin holds the client's newest token, and its refresh succeeds
    ///
    func testPluginRotationIsUsedByTheRestoredClient() async throws {
        let fresh = try XCTUnwrap(alice)
        let signIn = try await Amplify.Auth.signIn(username: fresh.username, password: fresh.password)
        XCTAssertTrue(signIn.isSignedIn, "alice did not sign in through the plugin")
        let first = try await pluginTokens().get().refreshToken
        let pluginRotated = try await pluginTokens(forceRefresh: true).get().refreshToken
        XCTAssertTrue(pluginRotated != first, "the plugin's refresh did not rotate the refresh token: is rotation on?")

        let clientRotated: String
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: .default))
            let state = await client.currentSessionState()
            guard case .signedIn(let restored) = state, restored.username == fresh.username else {
                return XCTFail("`.default` did not restore alice from the plugin's record")
            }
            let held = try await client.fetchAuthSession().userPoolTokensResult.get().refreshToken
            XCTAssertTrue(held == pluginRotated, "`.default` does not hold the plugin's rotated token")
            let refreshed = try await client.fetchAuthSession(options: .init(forceRefresh: true)).userPoolTokensResult
            guard case .success(let tokens) = refreshed else {
                return XCTFail("the client's refresh with the plugin's rotated token failed: \(Self.caseName(of: refreshed))")
            }
            XCTAssertTrue(tokens.refreshToken != pluginRotated, "the client's refresh did not rotate the token again")
            clientRotated = tokens.refreshToken
            let after = await client.currentSessionState()
            XCTAssertTrue(after == state, "`.default` is no longer signed in as alice after its refresh")
        }
        try await InteropEnvironment.waitUntilReleased(.default)

        try await relaunchPlugin()

        let held = try await pluginTokens()
        XCTAssertTrue((try? held.get().refreshToken) == clientRotated, "the relaunched plugin does not hold the client's newest token")
        let refreshed = try await pluginTokens(forceRefresh: true)
        if case .failure(let error) = refreshed {
            XCTFail("the relaunched plugin's refresh failed: \(Self.describe(error))")
        }
    }

    // MARK: - Helpers

    /// Without the rotation outputs: skips on CI and on any backend that is not the sandbox (the plugin's CI
    /// backends have no rotation client), and fails on the sandbox, where the client belongs (P-15). The sandbox is
    /// told by the marker `infra/plugin-configs.py --dir` puts in its outputs (`InteropEnvironment.isSandbox`); CI by
    /// `COGNITO_CLIENT_INTEG_CI_SKIPS=1`, which the client's CI job sets, or `CI` or `GITHUB_ACTIONS`. The test
    /// process gets only what xcodebuild's environment names with the `TEST_RUNNER_` prefix, under the name without
    /// it: the runner's own `CI` and `GITHUB_ACTIONS` never reach it unless passed as `TEST_RUNNER_CI` and
    /// `TEST_RUNNER_GITHUB_ACTIONS`.
    private static func skipOrFailWithoutTheRotationClient() throws {
        let environment = ProcessInfo.processInfo.environment
        let onCI = environment["COGNITO_CLIENT_INTEG_CI_SKIPS"] == "1"
            || ["CI", "GITHUB_ACTIONS"].contains { environment[$0] != nil }
        guard !onCI, InteropEnvironment.isSandbox else {
            throw XCTSkip("""
            \(outputsResource).json is not in the test bundle, and this is \(onCI ? "CI" : "not the sandbox"): no \
            backend there has an app client with refresh-token rotation.
            """)
        }
        throw InteropError("""
        \(outputsResource).json is not in the test bundle, on the sandbox. Provision the rotation client: run \
        infra/provision.sh (it adds the default pool's `rotation` client, P-15), then infra/plugin-configs.py --dir \
        <dir>, and rebuild with COGNITO_CLIENT_INTEG_DIR=<dir>.
        """)
    }

    /// Configures the plugin and waits until it has settled (`InteropEnvironment.settlePlugin()`), so a client on
    /// `.default` created next does not race it for the `authConfiguration` item.
    private func configurePlugin() async throws {
        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(with: .data(outputsData))
        try await InteropEnvironment.settlePlugin()
    }

    /// A new plugin over the same keychain, as at the app's next launch.
    private func relaunchPlugin() async throws {
        await Amplify.reset()
        try await configurePlugin()
    }

    /// The plugin's user pool tokens, optionally after a forced refresh. Never printed.
    private func pluginTokens(forceRefresh: Bool = false) async throws -> Result<AuthCognitoTokens, AuthError> {
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: forceRefresh))
        let provider = try XCTUnwrap(session as? AuthCognitoTokensProvider, "the plugin's session has no tokens")
        return provider.getCognitoTokens()
    }

    /// A plugin error by its case and its underlying error's type (`RefreshTokenReuseException`, say), never its text.
    private static func describe(_ error: AuthError) -> String {
        let caseName = Mirror(reflecting: error).children.first?.label ?? "?"
        return "\(caseName), underlying \(error.underlyingError.map { "\(type(of: $0))" } ?? "none")"
    }

    /// A client token result's error by its case name only, never its text or payload.
    private static func caseName(of result: Result<AuthClientUserPoolTokens, AuthClientError>) -> String {
        guard case .failure(let error) = result else {
            return "success"
        }
        let described = String(describing: error.kind)
        return described.firstIndex(of: "(").map { String(described[..<$0]) } ?? described
    }
}

extension InteropEnvironment {

    /// The outputs the rotation tests sign their fresh user up through, the role whose user pool the rotation
    /// client must be on: the extended role's when its file is in the bundle, else the default backend's.
    static var rotationBaseResource: String {
        rotationBaseResource(extendedPresent: bundle.url(forResource: extendedOutputsResource, withExtension: "json") != nil)
    }

    /// `rotationBaseResource` over whether the extended role's file is there, for the offline check.
    static func rotationBaseResource(extendedPresent: Bool) -> String {
        extendedPresent ? extendedOutputsResource : outputsResource
    }

    /// Whether the rotation client is on the user pool the fresh user is signed up on: both named, and the same.
    /// A file that names no user pool never passes, so the tests can only prove rotation on the pool their user is in.
    static func signsUpOnTheRotationPool(rotationPoolId: String?, basePoolId: String?) -> Bool {
        guard let rotationPoolId, let basePoolId else {
            return false
        }
        return rotationPoolId == basePoolId
    }
}

/// The rotation tests' choice of role and their same-pool rule, offline: no backend, no keychain.
final class RotationBaseRoleTests: XCTestCase {

    /// The rotation tests sign their user up on the role that holds the rotation client.
    ///
    /// - Given: `InteropEnvironment.rotationBaseResource(extendedPresent:)`
    /// - When:
    ///    - It is asked with and without the extended role's file
    /// - Then:
    ///    - With it, the extended role's outputs (the client's own CI pool, which holds the rotation client); without
    ///      it, the default backend's (the sandbox's default pool holds it there)
    ///
    func testTheUserIsSignedUpOnTheExtendedRoleWhenItsFileIsThere() {
        XCTAssertEqual(
            InteropEnvironment.rotationBaseResource(extendedPresent: true),
            "AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs"
        )
        XCTAssertEqual(
            InteropEnvironment.rotationBaseResource(extendedPresent: false),
            "AWSCognitoAuthPluginIntegrationTests-amplify_outputs"
        )
    }

    /// The rotation client must be on the fresh user's pool, and a missing pool never passes.
    ///
    /// - Given: `InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId:basePoolId:)`
    /// - When:
    ///    - It compares the same pool, two different pools, and a missing pool on either side or both
    /// - Then:
    ///    - Only the same, named pool passes
    ///
    func testTheRotationClientMustBeOnTheUsersPool() {
        XCTAssertTrue(InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId: "pool-a", basePoolId: "pool-a"))
        XCTAssertFalse(InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId: "pool-a", basePoolId: "pool-b"))
        XCTAssertFalse(InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId: nil, basePoolId: "pool-a"))
        XCTAssertFalse(InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId: "pool-a", basePoolId: nil))
        XCTAssertFalse(InteropEnvironment.signsUpOnTheRotationPool(rotationPoolId: nil, basePoolId: nil))
    }
}
