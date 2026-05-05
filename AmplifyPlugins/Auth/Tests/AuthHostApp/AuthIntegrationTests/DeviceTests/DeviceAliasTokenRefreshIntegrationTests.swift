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

    /// Test that rememberDevice succeeds with email alias login
    ///
    /// - Given: A user signed in with email alias (USER_SRP_AUTH)
    /// - When: rememberDevice is called
    /// - Then: It should succeed without "Unable to get device metadata" error
    func testRememberDeviceSucceedsWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        // This should not throw — device metadata should be found using inputUsername
        _ = try await Amplify.Auth.rememberDevice()

        // Verify device is listed
        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertGreaterThanOrEqual(devices.count, 1,
            "Should have at least 1 remembered device after rememberDevice()")
    }

    // MARK: - forgetDevice with Email Alias Tests

    /// Test that forgetDevice succeeds with email alias login
    ///
    /// - Given: A user signed in with email alias with a remembered device
    /// - When: forgetDevice is called
    /// - Then: It should succeed without "Unable to get device metadata" error
    func testForgetDeviceSucceedsWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        // Pool is "always remember" so device is auto-confirmed, but call remember
        // explicitly to ensure it's in the remembered state
        _ = try await Amplify.Auth.rememberDevice()

        // This should not throw — device metadata lookup uses inputUsername
        _ = try await Amplify.Auth.forgetDevice()

        // Verify device is no longer listed
        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devices.count, 0,
            "Device list should be empty after forgetDevice()")
    }

    /// Test that forgetDevice works after a token refresh with email alias
    ///
    /// - Given: A user signed in with email alias who has performed a token refresh
    /// - When: forgetDevice is called after the refresh
    /// - Then: It should succeed (inputUsername preserved through refresh cycle)
    func testForgetDeviceAfterTokenRefreshWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()

        // Force a token refresh first
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertTrue(session.isSignedIn)

        // Now forget — inputUsername must still be available after refresh
        _ = try await Amplify.Auth.forgetDevice()

        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devices.count, 0,
            "forgetDevice should work after token refresh with email alias")
    }

    // MARK: - fetchDevices with Email Alias Tests

    /// Test that fetchDevices returns device details with email alias login
    ///
    /// - Given: A user signed in with email alias with a remembered device
    /// - When: fetchDevices is called
    /// - Then: It should return the device with valid metadata
    func testFetchDevicesReturnsDetailsWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()

        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertGreaterThanOrEqual(devices.count, 1)

        guard let device = devices.first as? AWSAuthDevice else {
            XCTFail("Should be able to cast to AWSAuthDevice")
            return
        }
        XCTAssertFalse(device.id.isEmpty, "Device should have a non-empty ID")
        XCTAssertNotNil(device.createdDate, "Device should have a creation date")
        XCTAssertNotNil(device.lastAuthenticatedDate, "Device should have last authenticated date")
    }

    // MARK: - Device Persistence with Email Alias Tests

    /// Test that device persists across sign-out/sign-in with email alias
    ///
    /// - Given: A user signed in with email alias who has a remembered device
    /// - When: The user signs out and signs back in with the same email alias
    /// - Then: fetchDevices should return the same device (not a new one)
    func testDevicePersistsAcrossSignOutSignInWithEmailAlias() async throws {
        let firstResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(firstResult.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()
        let devicesAfterFirst = try await Amplify.Auth.fetchDevices()
        XCTAssertGreaterThanOrEqual(devicesAfterFirst.count, 1)
        let firstDeviceId = devicesAfterFirst.first?.id
        XCTAssertNotNil(firstDeviceId)

        // Sign out and back in
        _ = await Amplify.Auth.signOut()

        let secondResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(secondResult.isSignedIn)

        let devicesAfterSecond = try await Amplify.Auth.fetchDevices()
        XCTAssertGreaterThanOrEqual(devicesAfterSecond.count, 1,
            "Device should persist after sign-out/sign-in with email alias")
        XCTAssertEqual(devicesAfterSecond.first?.id, firstDeviceId,
            "Device ID should be the same after re-sign-in with email alias")
    }

    /// Test that token refresh works after sign-out/sign-in with email alias
    ///
    /// - Given: A user who signed in with email, signed out, and signed back in
    /// - When: fetchAuthSession is called with forceRefresh
    /// - Then: Token refresh succeeds (device metadata keychain key still resolves)
    func testTokenRefreshAfterDevicePersistenceWithEmailAlias() async throws {
        // First sign-in
        let firstResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(firstResult.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()

        // Sign out and back in
        _ = await Amplify.Auth.signOut()

        let secondResult = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(secondResult.isSignedIn)

        // Force refresh after re-sign-in — device metadata must be found
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertTrue(session.isSignedIn)

        if let cognitoSession = session as? AWSAuthCognitoSession {
            switch cognitoSession.userPoolTokensResult {
            case .success(let tokens):
                XCTAssertFalse(tokens.idToken.isEmpty)
                XCTAssertFalse(tokens.accessToken.isEmpty)
            case .failure(let error):
                XCTFail("Token refresh after re-sign-in failed: \(error). " +
                    "Device metadata not found after sign-out/sign-in cycle (issue #4207)")
            }
        }
    }

    // MARK: - Full Device Lifecycle with Email Alias

    /// Test the full device lifecycle: remember → fetch → forget → fetch with email alias
    ///
    /// - Given: A user signed in with email alias
    /// - When: The full device lifecycle is exercised
    /// - Then: Each operation succeeds without "Unable to get device metadata" errors
    func testFullDeviceLifecycleWithEmailAlias() async throws {
        let result = try await signInAndWait(
            username: defaultTestEmail,
            password: defaultTestPassword
        )
        XCTAssertTrue(result.isSignedIn)

        // Remember
        _ = try await Amplify.Auth.rememberDevice()

        // Fetch — should show the device
        let devicesAfterRemember = try await Amplify.Auth.fetchDevices()
        XCTAssertGreaterThanOrEqual(devicesAfterRemember.count, 1,
            "Should have at least 1 device after rememberDevice with email alias")
        let deviceId = devicesAfterRemember.first?.id
        XCTAssertNotNil(deviceId)

        // Token refresh mid-lifecycle — should still work
        let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
        XCTAssertTrue(session.isSignedIn)

        // Forget — should succeed using inputUsername for metadata lookup
        _ = try await Amplify.Auth.forgetDevice()

        // Fetch — should be empty now
        let devicesAfterForget = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterForget.count, 0,
            "Device list should be empty after forgetDevice with email alias")
    }
}
