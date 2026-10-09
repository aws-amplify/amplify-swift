//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Security
import XCTest

@testable import Amplify
import AWSPluginsCore
@testable import InternalAmplifyCredentials

/// `AmplifyAWSCredentialsProvider` and `AWSAuthService` report why a session has no credentials or
/// tokens, instead of `AuthError.unknown`.
///
/// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
/// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class CredentialResolutionErrorTests: XCTestCase, @unchecked Sendable {

    override func tearDown() async throws {
        await Amplify.reset()
    }

    // MARK: - AmplifyAWSCredentialsProvider

    /// A signed-out session reaches the AWS SDK as `invalidState`, on both entry points.
    ///
    /// - Given: `Amplify.Auth` returns a signed-out session that cannot vend credentials
    /// - When:
    ///    - `getCredentials()` and `getIdentity()` are called
    /// - Then:
    ///    - Both throw `AuthError.invalidState`
    ///
    func testCredentialsProvider_signedOutSession_throwsInvalidState() async throws {
        try SessionStubAuthPlugin.install(session: StubSignedOutSession())
        let provider = AmplifyAWSCredentialsProvider()

        let crtError = await authError { _ = try await provider.getCredentials() }
        let smithyError = await authError { _ = try await provider.getIdentity() }

        XCTAssertEqual(crtError.map(caseName), "invalidState")
        XCTAssertEqual(smithyError.map(caseName), "invalidState")
    }

    /// A user-pool-only session reaches the AWS SDK as a no-identity-pool `configuration` error.
    ///
    /// - Given: `Amplify.Auth` returns a signed-in session with user pool tokens and no credentials
    /// - When:
    ///    - `getCredentials()` and `getIdentity()` are called
    /// - Then:
    ///    - Both throw `AuthError.configuration` naming the missing identity pool
    ///
    func testCredentialsProvider_userPoolOnlySession_throwsNoIdentityPoolConfiguration() async throws {
        try SessionStubAuthPlugin.install(session: StubUserPoolOnlySession())
        let provider = AmplifyAWSCredentialsProvider()

        for error in [
            await authError { _ = try await provider.getCredentials() },
            await authError { _ = try await provider.getIdentity() }
        ] {
            guard case .configuration(let description, _, _) = error else {
                XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
                continue
            }
            XCTAssertTrue(description.contains("no identity pool"), description)
        }
    }

    /// A keychain failure reaches the AWS SDK as the session reported it.
    ///
    /// - Given: `Amplify.Auth` returns a session whose credentials failed with a locked keychain
    /// - When:
    ///    - `getCredentials()` and `getIdentity()` are called
    /// - Then:
    ///    - Both throw the session's `AuthError.service`, with the keychain error underneath
    ///
    func testCredentialsProvider_keychainLockedSession_propagatesSessionError() async throws {
        try SessionStubAuthPlugin.install(session: StubKeychainLockedSession())
        let provider = AmplifyAWSCredentialsProvider()

        assertIsKeychainLocked(await authError { _ = try await provider.getCredentials() })
        assertIsKeychainLocked(await authError { _ = try await provider.getIdentity() })
    }

    // MARK: - AWSAuthService

    /// A signed-out session has no identity ID and no access token, and says so.
    ///
    /// - Given: `Amplify.Auth` returns a signed-out session that vends nothing
    /// - When:
    ///    - `getIdentityID()` and `getUserPoolAccessToken()` are called
    /// - Then:
    ///    - Both throw `AuthError.invalidState`
    ///
    func testAuthService_signedOutSession_throwsInvalidState() async throws {
        try SessionStubAuthPlugin.install(session: StubSignedOutSession())
        let service = AWSAuthService()

        let identityError = await authError { _ = try await service.getIdentityID() }
        let tokenError = await authError { _ = try await service.getUserPoolAccessToken() }

        XCTAssertEqual(identityError.map(caseName), "invalidState")
        XCTAssertEqual(tokenError.map(caseName), "invalidState")
    }

    /// A user-pool-only session has an access token but no identity ID.
    ///
    /// - Given: `Amplify.Auth` returns a signed-in session with user pool tokens only
    /// - When:
    ///    - `getIdentityID()` and `getUserPoolAccessToken()` are called
    /// - Then:
    ///    - `getIdentityID()` throws a no-identity-pool `AuthError.configuration`
    ///    - `getUserPoolAccessToken()` returns the access token
    ///
    func testAuthService_userPoolOnlySession_hasTokenButNoIdentityID() async throws {
        try SessionStubAuthPlugin.install(session: StubUserPoolOnlySession())
        let service = AWSAuthService()

        let identityError = await authError { _ = try await service.getIdentityID() }
        guard case .configuration(let description, _, _) = identityError else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: identityError))")
        }
        XCTAssertTrue(description.contains("no identity pool"), description)

        let token = try await service.getUserPoolAccessToken()
        XCTAssertEqual(token, "accessToken")
    }

    /// A keychain failure reaches `AWSAuthService` callers as the session reported it.
    ///
    /// - Given: `Amplify.Auth` returns a session whose values failed with a locked keychain
    /// - When:
    ///    - `getIdentityID()` and `getUserPoolAccessToken()` are called
    /// - Then:
    ///    - Both throw the session's `AuthError.service`, with the keychain error underneath
    ///
    func testAuthService_keychainLockedSession_propagatesSessionError() async throws {
        try SessionStubAuthPlugin.install(session: StubKeychainLockedSession())
        let service = AWSAuthService()

        assertIsKeychainLocked(await authError { _ = try await service.getIdentityID() })
        assertIsKeychainLocked(await authError { _ = try await service.getUserPoolAccessToken() })
    }

    // MARK: - Helpers

    private func authError(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async -> AuthError? {
        do {
            try await body()
            XCTFail("Expected an AuthError", file: file, line: line)
            return nil
        } catch let error as AuthError {
            XCTAssertNotEqual(caseName(error), "unknown", "\(error)", file: file, line: line)
            return error
        } catch {
            XCTFail("Expected an AuthError, got \(error)", file: file, line: line)
            return nil
        }
    }

    private func assertIsKeychainLocked(
        _ error: AuthError?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .service(let description, _, let underlying) = error else {
            return XCTFail("Expected AuthError.service, got \(String(describing: error))", file: file, line: line)
        }
        XCTAssertEqual(description, StubKeychainLockedSession.errorDescription, file: file, line: line)
        guard case .securityError(let status) = underlying as? KeychainStoreError else {
            return XCTFail("Expected the keychain error, got \(String(describing: underlying))", file: file, line: line)
        }
        XCTAssertEqual(status, errSecInteractionNotAllowed, file: file, line: line)
    }
}

/// The name of an `AuthError` case. `AuthError`'s `==` is `false` for any two `.unknown` values, so
/// assertions compare names.
private func caseName(_ error: AuthError) -> String {
    switch error {
    case .configuration: "configuration"
    case .service: "service"
    case .unknown: "unknown"
    case .validation: "validation"
    case .notAuthorized: "notAuthorized"
    case .invalidState: "invalidState"
    case .signedOut: "signedOut"
    case .sessionExpired: "sessionExpired"
    }
}
