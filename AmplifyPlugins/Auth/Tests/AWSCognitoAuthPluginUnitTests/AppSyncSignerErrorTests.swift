//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Foundation
import Security
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// `createAppSyncSigner` reports why the current session cannot sign, instead of `AuthError.unknown`.
///
/// The signer reads the session through `Amplify.Auth`, so each test installs the session it needs
/// there. Sessions from `AWSCognitoAuthPlugin` always carry credentials or their own error, which the
/// signer propagates; a session that cannot vend credentials at all (another Auth plugin) is classified.
class AppSyncSignerErrorTests: BaseAuthorizationTests, @unchecked Sendable {

    private let request: URLRequest = {
        var request = URLRequest(url: URL(string: "https://abc.appsync-api.us-east-1.amazonaws.com/graphql")!)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        return request
    }()

    /// The Auth category to put back. Restoring only it, rather than calling `Amplify.reset()`, leaves
    /// every other category, Hub included, as the rest of this target's tests expect to find it.
    private var originalAuth: AuthCategory?

    override func setUp() {
        super.setUp()
        originalAuth = Amplify.Auth
    }

    override func tearDown() {
        if let originalAuth {
            Amplify.Auth = originalAuth
        }
        super.tearDown()
    }

    // MARK: - Sessions that cannot vend credentials

    /// A signed-out session produces `invalidState`, not `unknown`, through the public signer.
    ///
    /// - Given: `Amplify.Auth` returns a signed-out session that does not conform to
    ///   `AuthAWSCredentialsProvider`
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws `AuthError.invalidState`
    ///
    func testCreateAppSyncSigner_signedOutSession_throwsInvalidState() async throws {
        try install(StubSignedOutSession())

        let error = await signingError()

        guard case .invalidState = error else {
            return XCTFail("Expected AuthError.invalidState, got \(String(describing: error))")
        }
    }

    /// A user-pool-only session produces a `configuration` error that names the missing identity pool.
    ///
    /// - Given: `Amplify.Auth` returns a signed-in session with user pool tokens and no credentials
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws `AuthError.configuration` naming the missing identity pool
    ///
    func testCreateAppSyncSigner_userPoolOnlySession_throwsNoIdentityPoolConfiguration() async throws {
        try install(StubUserPoolOnlySession())

        let error = await signingError()

        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("no identity pool"), description)
    }

    // MARK: - AWSCognitoAuthPlugin sessions

    /// A Cognito session signed out without guest access keeps the plugin's own error.
    ///
    /// - Given: `Amplify.Auth` returns the plugin's signed-out session for an identity pool that does not
    ///   allow guest access
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws the session's `AuthError.service` for a signed-out user, with
    ///      `AWSCognitoAuthError.invalidAccountTypeException` underneath
    ///
    func testCreateAppSyncSigner_cognitoSignedOutWithoutGuestAccess_propagatesSessionError() async throws {
        try install(AuthCognitoSignedOutSessionHelper.makeSessionWithNoGuestAccess())

        let error = await signingError()

        guard case .service(let description, _, let underlying) = error else {
            return XCTFail("Expected AuthError.service, got \(String(describing: error))")
        }
        XCTAssertEqual(description, AuthPluginErrorConstants.awsCredentialsSignOutError.errorDescription)
        guard case .invalidAccountTypeException = underlying as? AWSCognitoAuthError else {
            return XCTFail("Expected invalidAccountTypeException, got \(String(describing: underlying))")
        }
    }

    /// A Cognito user-pool-only session keeps the plugin's own no-identity-pool error.
    ///
    /// - Given: `Amplify.Auth` returns the plugin's session for a signed-in user with no identity pool
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws the session's `AuthError.service` naming the missing identity pool
    ///
    func testCreateAppSyncSigner_cognitoUserPoolOnly_propagatesSessionError() async throws {
        try install(AmplifyCredentials.userPoolOnly(signedInData: .longLived).cognitoSession)

        let error = await signingError()

        guard case .service(let description, _, _) = error else {
            return XCTFail("Expected AuthError.service, got \(String(describing: error))")
        }
        XCTAssertEqual(
            description,
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.errorDescription
        )
    }

    /// A Cognito session whose keychain read failed keeps the keychain's error.
    ///
    /// - Given: `Amplify.Auth` returns a plugin session whose results failed with a locked keychain,
    ///   mapped the way the plugin maps `KeychainStoreError`
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws the session's `AuthError.service` with the keychain's description
    ///
    func testCreateAppSyncSigner_cognitoKeychainLocked_propagatesSessionError() async throws {
        let keychainError = KeychainStoreError.securityError(errSecInteractionNotAllowed)
        try install(AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .failure(keychainError.authError),
            awsCredentialsResult: .failure(keychainError.authError),
            cognitoTokensResult: .failure(keychainError.authError)
        ))

        let error = await signingError()

        guard case .service(let description, _, _) = error else {
            return XCTFail("Expected AuthError.service, got \(String(describing: error))")
        }
        XCTAssertEqual(description, keychainError.errorDescription)
    }

    /// End to end through a configured plugin: no identity pool is reported, not `unknown`.
    ///
    /// - Given: A configured `AWSCognitoAuthPlugin`, installed as `Amplify.Auth`, with a signed-in user
    ///   and no identity pool
    /// - When:
    ///    - The closure from `createAppSyncSigner(region:)` signs a request
    /// - Then:
    ///    - It throws the plugin's no-identity-pool `AuthError.service`
    ///
    func testCreateAppSyncSigner_configuredPluginWithoutIdentityPool_throwsPluginError() async throws {
        let plugin = configurePluginWith(initialState: .configured(
            .signedIn(.longLived),
            .sessionEstablished(.userPoolOnly(signedInData: .longLived)),
            .notStarted
        ))
        try install(plugin: plugin)

        let error = await signingError()

        guard case .service(let description, _, _) = error else {
            return XCTFail("Expected AuthError.service, got \(String(describing: error))")
        }
        XCTAssertEqual(
            description,
            AuthPluginErrorConstants.signedInAWSCredentialsWithNoCIDPError.errorDescription
        )
    }

    // MARK: - Helpers

    private func install(_ session: AuthSession) throws {
        try install(plugin: SessionStubAuthPlugin(session: session))
    }

    private func install(plugin: AuthCategoryPlugin) throws {
        let category = AuthCategory()
        try category.add(plugin: plugin)
        category.isConfigured = true
        Amplify.Auth = category
    }

    private func signingError(file: StaticString = #filePath, line: UInt = #line) async -> AuthError? {
        let sign = AWSCognitoAuthPlugin.createAppSyncSigner(region: "us-east-1")
        do {
            _ = try await sign(request)
            XCTFail("Expected signing to fail", file: file, line: line)
            return nil
        } catch let error as AuthError {
            if case .unknown = error {
                XCTFail("Expected a specific AuthError, got \(error)", file: file, line: line)
            }
            return error
        } catch {
            XCTFail("Expected an AuthError, got \(error)", file: file, line: line)
            return nil
        }
    }
}

/// An Auth plugin whose `fetchAuthSession` returns a fixed session.
///
/// `@unchecked Sendable`: a test double driven from one test at a time.
private final class SessionStubAuthPlugin: MockAuthCategoryPlugin, @unchecked Sendable {
    let session: AuthSession

    init(session: AuthSession) {
        self.session = session
        super.init()
    }

    override func fetchAuthSession(options: AuthFetchSessionRequest.Options? = nil) async throws -> AuthSession {
        session
    }
}

/// What a third-party Auth plugin might return when no one is signed in: a bare `AuthSession`.
private struct StubSignedOutSession: AuthSession {
    let isSignedIn = false
}

/// A signed-in session from another Auth plugin with user pool tokens and no identity pool.
private struct StubUserPoolOnlySession: AuthSession, AuthCognitoTokensProvider {
    let isSignedIn = true

    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        .success(AWSCognitoUserPoolTokens.longLived)
    }
}

private extension SignedInData {
    /// Signed-in data whose tokens outlive the plugin's refresh buffer, so no refresh is attempted.
    static var longLived: SignedInData {
        SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: .init(AWSCognitoUserPoolTokens.longLived)
        )
    }
}

private extension AWSCognitoUserPoolTokens {
    static var longLived: AWSCognitoUserPoolTokens {
        let expiry = Date(timeIntervalSinceNow: 3_600)
        let claims = [
            "sub": "1234567890",
            "username": "John Doe",
            "iat": "1516239022",
            "exp": String(expiry.timeIntervalSince1970)
        ]
        return AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: claims),
            accessToken: CognitoAuthTestHelper.buildToken(for: claims),
            refreshToken: "refreshToken"
        )
    }
}
