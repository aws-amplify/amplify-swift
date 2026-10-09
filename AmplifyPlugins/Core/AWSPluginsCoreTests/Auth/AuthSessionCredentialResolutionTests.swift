//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation
import Security
import XCTest

/// `AuthSession.resolveAWSCredentials()`, `resolveCognitoTokens()` and `resolveIdentityID()` replace the
/// downcasts that used to collapse every missing value into `AuthError.unknown`.
class AuthSessionCredentialResolutionTests: XCTestCase {

    // MARK: - AWS credentials

    /// A session that is signed out and cannot vend credentials reports that it is signed out.
    ///
    /// - Given: A signed-out session that does not conform to `AuthAWSCredentialsProvider`
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It throws `AuthError.invalidState`, not `AuthError.unknown`
    ///
    func testResolveAWSCredentials_signedOutSession_throwsInvalidState() {
        let error = resolutionError { try SignedOutSession().resolveAWSCredentials() }
        guard case .invalidState = error else {
            return XCTFail("Expected AuthError.invalidState, got \(String(describing: error))")
        }
    }

    /// A signed-in session with user pool tokens but no credentials has no identity pool.
    ///
    /// - Given: A signed-in session that vends user pool tokens but does not conform to
    ///   `AuthAWSCredentialsProvider`
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` that names the missing identity pool
    ///
    func testResolveAWSCredentials_userPoolOnlySession_throwsNoIdentityPoolConfiguration() {
        let error = resolutionError { try UserPoolOnlySession().resolveAWSCredentials() }
        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("no identity pool"), description)
    }

    /// A signed-in session that vends nothing is the Auth plugin's misconfiguration.
    ///
    /// - Given: A signed-in session that conforms to none of the provider protocols
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` that names the protocol the session lacks
    ///
    func testResolveAWSCredentials_signedInSessionWithoutProviders_throwsConfiguration() {
        let error = resolutionError { try SignedInSessionWithoutProviders().resolveAWSCredentials() }
        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("AuthAWSCredentialsProvider"), description)
        XCTAssertFalse(description.contains("no identity pool"), description)
    }

    /// A keychain failure the session already reported is propagated, not re-derived.
    ///
    /// - Given: A conforming session whose credentials result is a keychain-locked storage failure
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It throws the session's own error: same case, description and underlying keychain error
    ///
    func testResolveAWSCredentials_keychainLockedSession_propagatesSessionError() {
        let error = resolutionError { try ProvidingSession.keychainLocked.resolveAWSCredentials() }
        assertIsKeychainLockedError(error)
    }

    /// An expired-credentials failure the session already reported is propagated.
    ///
    /// - Given: A conforming session whose credentials result is `AuthError.sessionExpired`
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It throws `AuthError.sessionExpired`
    ///
    func testResolveAWSCredentials_expiredSession_propagatesSessionExpired() {
        let session = ProvidingSession(failure: .sessionExpired("expired", "sign in again"))
        let error = resolutionError { try session.resolveAWSCredentials() }
        guard case .sessionExpired = error else {
            return XCTFail("Expected AuthError.sessionExpired, got \(String(describing: error))")
        }
    }

    /// A conforming session with credentials returns them.
    ///
    /// - Given: A conforming session with valid credentials
    /// - When:
    ///    - `resolveAWSCredentials()` is called
    /// - Then:
    ///    - It returns the session's credentials
    ///
    func testResolveAWSCredentials_sessionWithCredentials_returnsThem() throws {
        let credentials = try ProvidingSession.valid.resolveAWSCredentials()
        XCTAssertEqual(credentials.accessKeyId, "accessKeyId")
        XCTAssertEqual(credentials.secretAccessKey, "secretAccessKey")
    }

    /// The three failures the downcast used to flatten into one `unknown` are now three different cases.
    ///
    /// - Given: A signed-out session, a user-pool-only session, and a keychain-locked session
    /// - When:
    ///    - `resolveAWSCredentials()` is called on each
    /// - Then:
    ///    - The errors are `invalidState`, `configuration` and `service`: pairwise distinct, none `unknown`
    ///
    func testResolveAWSCredentials_distinguishesSignedOutNoIdentityPoolAndKeychainLocked() {
        let errors: [AuthError?] = [
            resolutionError { try SignedOutSession().resolveAWSCredentials() },
            resolutionError { try UserPoolOnlySession().resolveAWSCredentials() },
            resolutionError { try ProvidingSession.keychainLocked.resolveAWSCredentials() }
        ]
        let cases = errors.map { $0.map(caseName) }
        XCTAssertEqual(cases, ["invalidState", "configuration", "service"])
    }

    /// Every error the resolver derives itself uses a case that no consumer branches on differently from
    /// `.unknown`, which it replaced.
    ///
    /// DataStore's `SyncMutationToCloudOperation`, `InitialSyncOperation` and
    /// `ProcessMutationErrorFromCloudOperation`, and Pinpoint's `EventRecorder`, special-case `.signedOut`
    /// and `.sessionExpired`. `RetryableGraphQLOperation` special-cases `.notAuthorized`.
    ///
    /// - Given: Signed-out, user-pool-only and provider-less sessions that do not conform
    /// - When:
    ///    - Each of the three resolve methods is called
    /// - Then:
    ///    - Every error is `.invalidState` or `.configuration`, never a special-cased case
    ///
    func testDerivedErrors_useOnlyCasesConsumersTreatLikeUnknown() {
        let sessions: [AuthSession] = [SignedOutSession(), UserPoolOnlySession(), SignedInSessionWithoutProviders()]
        var derived: [AuthError] = []
        for session in sessions {
            if let error = try? catchAuthError({ try session.resolveAWSCredentials() }) { derived.append(error) }
            if let error = try? catchAuthError({ try session.resolveIdentityID() }) { derived.append(error) }
            if let error = try? catchAuthError({ try session.resolveCognitoTokens() }) { derived.append(error) }
        }

        // The user-pool-only session vends tokens, so 8 of the 9 calls fail.
        XCTAssertEqual(derived.count, 8)
        for error in derived {
            XCTAssertTrue(["invalidState", "configuration"].contains(caseName(error)), "\(error)")
        }
    }

    // MARK: - User pool tokens

    /// A signed-out session without tokens reports that it is signed out.
    ///
    /// - Given: A signed-out session that does not conform to `AuthCognitoTokensProvider`
    /// - When:
    ///    - `resolveCognitoTokens()` is called
    /// - Then:
    ///    - It throws `AuthError.invalidState`
    ///
    func testResolveCognitoTokens_signedOutSession_throwsInvalidState() {
        let error = resolutionError { try SignedOutSession().resolveCognitoTokens() }
        guard case .invalidState = error else {
            return XCTFail("Expected AuthError.invalidState, got \(String(describing: error))")
        }
    }

    /// A signed-in session that vends no tokens is the Auth plugin's misconfiguration.
    ///
    /// - Given: A signed-in session that does not conform to `AuthCognitoTokensProvider`
    /// - When:
    ///    - `resolveCognitoTokens()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` that names the protocol the session lacks
    ///
    func testResolveCognitoTokens_signedInSessionWithoutProviders_throwsConfiguration() {
        let error = resolutionError { try SignedInSessionWithoutProviders().resolveCognitoTokens() }
        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("AuthCognitoTokensProvider"), description)
    }

    /// A keychain failure the session already reported is propagated for tokens too.
    ///
    /// - Given: A conforming session whose tokens result is a keychain-locked storage failure
    /// - When:
    ///    - `resolveCognitoTokens()` is called
    /// - Then:
    ///    - It throws the session's own error
    ///
    func testResolveCognitoTokens_keychainLockedSession_propagatesSessionError() {
        let error = resolutionError { try ProvidingSession.keychainLocked.resolveCognitoTokens() }
        assertIsKeychainLockedError(error)
    }

    /// A user-pool-only session vends its tokens.
    ///
    /// - Given: A signed-in session that conforms only to `AuthCognitoTokensProvider`
    /// - When:
    ///    - `resolveCognitoTokens()` is called
    /// - Then:
    ///    - It returns the tokens
    ///
    func testResolveCognitoTokens_userPoolOnlySession_returnsTokens() throws {
        XCTAssertEqual(try UserPoolOnlySession().resolveCognitoTokens().accessToken, "accessToken")
    }

    // MARK: - Identity ID

    /// A signed-out session without an identity ID reports that it is signed out.
    ///
    /// - Given: A signed-out session that does not conform to `AuthCognitoIdentityProvider`
    /// - When:
    ///    - `resolveIdentityID()` is called
    /// - Then:
    ///    - It throws `AuthError.invalidState`
    ///
    func testResolveIdentityID_signedOutSession_throwsInvalidState() {
        let error = resolutionError { try SignedOutSession().resolveIdentityID() }
        guard case .invalidState = error else {
            return XCTFail("Expected AuthError.invalidState, got \(String(describing: error))")
        }
    }

    /// A signed-in session with user pool tokens but no identity ID has no identity pool.
    ///
    /// - Given: A signed-in session that vends user pool tokens but does not conform to
    ///   `AuthCognitoIdentityProvider`
    /// - When:
    ///    - `resolveIdentityID()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` that names the missing identity pool
    ///
    func testResolveIdentityID_userPoolOnlySession_throwsNoIdentityPoolConfiguration() {
        let error = resolutionError { try UserPoolOnlySession().resolveIdentityID() }
        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("no identity pool"), description)
    }

    /// A signed-in session that vends nothing is the Auth plugin's misconfiguration.
    ///
    /// - Given: A signed-in session that conforms to none of the provider protocols
    /// - When:
    ///    - `resolveIdentityID()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` that names the protocol the session lacks
    ///
    func testResolveIdentityID_signedInSessionWithoutProviders_throwsConfiguration() {
        let error = resolutionError { try SignedInSessionWithoutProviders().resolveIdentityID() }
        guard case .configuration(let description, _, _) = error else {
            return XCTFail("Expected AuthError.configuration, got \(String(describing: error))")
        }
        XCTAssertTrue(description.contains("AuthCognitoIdentityProvider"), description)
    }

    /// A keychain failure the session already reported is propagated for the identity ID too.
    ///
    /// - Given: A conforming session whose identity ID result is a keychain-locked storage failure
    /// - When:
    ///    - `resolveIdentityID()` is called
    /// - Then:
    ///    - It throws the session's own error
    ///
    func testResolveIdentityID_keychainLockedSession_propagatesSessionError() {
        let error = resolutionError { try ProvidingSession.keychainLocked.resolveIdentityID() }
        assertIsKeychainLockedError(error)
    }

    /// A conforming session with an identity ID returns it.
    ///
    /// - Given: A conforming session with an identity ID
    /// - When:
    ///    - `resolveIdentityID()` is called
    /// - Then:
    ///    - It returns the identity ID
    ///
    func testResolveIdentityID_sessionWithIdentityID_returnsIt() throws {
        XCTAssertEqual(try ProvidingSession.valid.resolveIdentityID(), "identityId")
    }

    // MARK: - Helpers

    private func resolutionError<Value>(_ body: () throws -> Value) -> AuthError? {
        do {
            _ = try body()
            XCTFail("Expected an AuthError")
            return nil
        } catch let error as AuthError {
            XCTAssertNotEqual(caseName(error), "unknown", "\(error)")
            return error
        } catch {
            XCTFail("Expected an AuthError, got \(error)")
            return nil
        }
    }

    /// The `AuthError` `body` throws, or `nil` when it succeeds.
    private func catchAuthError<Value>(_ body: () throws -> Value) throws -> AuthError? {
        do {
            _ = try body()
            return nil
        } catch let error as AuthError {
            return error
        }
    }

    private func assertIsKeychainLockedError(
        _ error: AuthError?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .service(let description, _, let underlying) = error else {
            return XCTFail("Expected the session's AuthError.service, got \(String(describing: error))", file: file, line: line)
        }
        XCTAssertEqual(description, ProvidingSession.keychainLockedDescription, file: file, line: line)
        guard case .securityError(let status) = underlying as? KeychainStoreError else {
            return XCTFail("Expected the keychain error to survive, got \(String(describing: underlying))", file: file, line: line)
        }
        XCTAssertEqual(status, errSecInteractionNotAllowed, file: file, line: line)
    }
}

/// The name of an `AuthError` case, for asserting on cases without `AuthError`'s `==`, which is `false`
/// for any two `.unknown` values.
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

// MARK: - Sessions

/// What a third-party Auth plugin might return when no one is signed in: a bare `AuthSession`.
private struct SignedOutSession: AuthSession {
    let isSignedIn = false
}

/// A signed-in session from a plugin that vends none of the provider protocols.
private struct SignedInSessionWithoutProviders: AuthSession {
    let isSignedIn = true
}

/// A signed-in user pool session with no identity pool behind it.
private struct UserPoolOnlySession: AuthSession, AuthCognitoTokensProvider {
    let isSignedIn = true

    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        .success(Tokens())
    }
}

/// A session that conforms to every provider protocol and reports `failure`, if any, for each.
private struct ProvidingSession: AuthSession, AuthAWSCredentialsProvider, AuthCognitoTokensProvider,
    AuthCognitoIdentityProvider {

    static let keychainLockedDescription = "The keychain could not be read"

    /// A storage failure shaped the way `AWSCognitoAuthPlugin` reports a locked keychain:
    /// `KeychainStoreError.securityError` mapped to `AuthError.service`.
    static let keychainLocked = ProvidingSession(failure: .service(
        keychainLockedDescription,
        "Unlock the device and retry",
        KeychainStoreError.securityError(errSecInteractionNotAllowed)
    ))

    static let valid = ProvidingSession(failure: nil)

    let isSignedIn = true
    let failure: AuthError?

    func getAWSCredentials() -> Result<AWSCredentials, AuthError> {
        failure.map { .failure($0) } ?? .success(Credentials())
    }

    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        failure.map { .failure($0) } ?? .success(Tokens())
    }

    func getIdentityId() -> Result<String, AuthError> {
        failure.map { .failure($0) } ?? .success("identityId")
    }

    func getUserSub() -> Result<String, AuthError> {
        failure.map { .failure($0) } ?? .success("sub")
    }
}

private struct Tokens: AuthCognitoTokens {
    let idToken = "idToken"
    let accessToken = "accessToken"
    let refreshToken = "refreshToken"
}

private struct Credentials: AWSTemporaryCredentials {
    let accessKeyId = "accessKeyId"
    let secretAccessKey = "secretAccessKey"
    let sessionToken = "sessionToken"
    let expiration = Date(timeIntervalSinceNow: 3_600)
}
