//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

/// Integration tests for token refresh with device tracking and email alias login.
///
/// These tests verify that token refresh works correctly when a user signs in
/// with an email alias (where inputUsername != JWT username/sub). This is a
/// regression test for https://github.com/aws-amplify/amplify-swift/issues/4207.
///
/// Prerequisites:
/// - Cognito User Pool with email as usernameAttribute (alias-based auth)
/// - Device Tracking set to "Always Remember"
/// - Short token validity (5 min) configured via CDK override
/// - Pre-created test user (credentials in testconfiguration/AWSCognitoAuthPluginDeviceAliasTests-credentials.json)
/// - Backend definition in infra/device-alias-test/ (not committed, see README)
/// - Config: testconfiguration/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json
class DeviceAliasTokenRefreshIntegrationTests: AWSAuthBaseTest {

    var unsubscribeToken: UnsubscribeToken!

    override func setUp() async throws {
        onlyUseGen2Configuration = true
        amplifyOutputsFile = "testconfiguration/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs"
        try await super.setUp()
        // Load credentials from our custom credentials file
        let credentials = (try? TestConfigHelper.retrieveCredentials(
            forResource: "testconfiguration/AWSCognitoAuthPluginDeviceAliasTests-credentials"
        )) ?? [:]
        defaultTestEmail = credentials["test_email_1"] ?? defaultTestEmail
        defaultTestPassword = credentials["password"] ?? defaultTestPassword
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    // MARK: - Helpers

    private func signInAndWait(
        username: String,
        password: String
    ) async throws -> AuthSignInResult {
        let signInExpectation = expectation(description: "Sign in")
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            if payload.eventName == HubPayload.EventName.Auth.signedIn {
                signInExpectation.fulfill()
            }
        }

        let result = try await Amplify.Auth.signIn(
            username: username,
            password: password,
            options: .init(pluginOptions: AWSAuthSignInOptions(authFlowType: .userSRP))
        )
        await fulfillment(of: [signInExpectation], timeout: networkTimeout)
        Amplify.Hub.removeListener(unsubscribeToken)
        return result
    }

    // MARK: - Token Refresh with Email Alias Tests (issue #4207)

    /// Test that token refresh succeeds when signed in with email alias and device tracking
    ///
    /// - Given: A user signed in with email alias (USER_SRP_AUTH) with device remembered
    /// - When: fetchAuthSession is called with forceRefresh
    /// - Then: The session should contain valid refreshed tokens (not "Invalid Refresh Token")
    func testTokenRefreshSucceedsWithEmailAliasAndDeviceTracking() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        // Device is automatically remembered (pool configured with "always remember")
        // Force refresh — this triggers the device metadata lookup
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertTrue(session.isSignedIn)

        if let cognitoSession = session as? AWSAuthCognitoSession {
            switch cognitoSession.userPoolTokensResult {
            case .success(let tokens):
                XCTAssertFalse(tokens.idToken.isEmpty)
                XCTAssertFalse(tokens.accessToken.isEmpty)
            case .failure(let error):
                XCTFail("Token refresh failed with email alias + device tracking: \(error). " +
                    "Device metadata keychain key mismatch (issue #4207)")
            }
        }
    }

    /// Test that consecutive token refreshes succeed with email alias and device tracking
    ///
    /// - Given: A user signed in with email alias (USER_SRP_AUTH) with device remembered
    /// - When: fetchAuthSession is called with forceRefresh twice
    /// - Then: Both refreshes succeed (inputUsername preserved across refreshes)
    func testConsecutiveTokenRefreshesWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        // First refresh
        let session1 = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        if let cognitoSession = session1 as? AWSAuthCognitoSession {
            switch cognitoSession.userPoolTokensResult {
            case .success(let tokens):
                XCTAssertFalse(tokens.idToken.isEmpty)
            case .failure(let error):
                XCTFail("First refresh failed: \(error)")
            }
        }

        // Second refresh — fails if inputUsername not preserved after first refresh
        let session2 = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        if let cognitoSession = session2 as? AWSAuthCognitoSession {
            switch cognitoSession.userPoolTokensResult {
            case .success(let tokens):
                XCTAssertFalse(tokens.idToken.isEmpty)
            case .failure(let error):
                XCTFail("Second refresh failed — inputUsername not preserved: \(error) (issue #4207)")
            }
        }
    }

    /// Test that token refresh succeeds after sign-out/sign-in with email alias
    ///
    /// - Given: A user who signed in with email, remembered device, signed out, signed back in
    /// - When: fetchAuthSession is called with forceRefresh
    /// - Then: Token refresh succeeds
    func testTokenRefreshAfterReSignInWithEmailAlias() async throws {
        // First sign-in + remember device
        let firstResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(firstResult.isSignedIn)

        // Sign out
        _ = await Amplify.Auth.signOut()

        // Second sign-in
        let secondResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(secondResult.isSignedIn)

        // Force refresh after re-sign-in
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertTrue(session.isSignedIn)

        if let cognitoSession = session as? AWSAuthCognitoSession {
            switch cognitoSession.userPoolTokensResult {
            case .success(let tokens):
                XCTAssertFalse(tokens.idToken.isEmpty)
            case .failure(let error):
                XCTFail("Token refresh after re-sign-in with email alias failed: \(error) (issue #4207)")
            }
        }
    }
}
