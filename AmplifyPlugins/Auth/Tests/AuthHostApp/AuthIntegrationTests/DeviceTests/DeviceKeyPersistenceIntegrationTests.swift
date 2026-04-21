//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

/// Integration tests for device key persistence across sign-in/sign-out cycles
/// and across different authentication flows (USER_SRP_AUTH vs USER_PASSWORD_AUTH).
///
/// These tests verify that once a device is registered via rememberDevice(),
/// subsequent sign-in attempts reuse the same device ID rather than generating
/// a new one — even when the auth flow changes between sign-ins. This is critical
/// for flows where external systems (e.g., payment processors) link data to
/// Cognito device IDs.
///
/// Prerequisites:
/// - Cognito User Pool with Device Tracking set to "Always Remember"
/// - User Pool must allow both USER_SRP_AUTH and USER_PASSWORD_AUTH flows
/// - Valid test configuration in testconfiguration/ resources
class DeviceKeyPersistenceIntegrationTests: AWSAuthBaseTest {

    var unsubscribeToken: UnsubscribeToken!

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    // MARK: - Helpers

    private func signInAndWait(
        username: String,
        password: String,
        authFlowType: AuthFlowType? = nil
    ) async throws -> AuthSignInResult {
        let signInExpectation = expectation(description: "Sign in with \(authFlowType?.description ?? "default")")
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            if payload.eventName == HubPayload.EventName.Auth.signedIn {
                signInExpectation.fulfill()
            }
        }

        let options: AuthSignInRequest.Options?
        if let authFlowType {
            options = .init(pluginOptions: AWSAuthSignInOptions(authFlowType: authFlowType))
        } else {
            options = nil
        }

        let result = try await Amplify.Auth.signIn(
            username: username,
            password: password,
            options: options
        )
        await fulfillment(of: [signInExpectation], timeout: networkTimeout)
        Amplify.Hub.removeListener(unsubscribeToken)
        return result
    }

    // MARK: - Same flow tests

    /// Test that device ID persists across sign-out and sign-in with the same flow
    ///
    /// - Given: A registered user who has called rememberDevice after SRP sign-in
    /// - When: The user signs out and signs back in with SRP
    /// - Then: fetchDevices should return the same device ID (no duplicate)
    func testDeviceKeyPersistsAcrossSignOutSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        // Default flow is USER_SRP_AUTH; registerAndSignInUser doesn't wait for hub
        // so sign in again explicitly
        _ = await Amplify.Auth.signOut()

        _ = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userSRP
        )

        _ = try await Amplify.Auth.rememberDevice()
        let devicesAfterFirst = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterFirst.count, 1, "Should have exactly 1 device after first sign-in")
        let firstDeviceId = devicesAfterFirst.first?.id
        XCTAssertNotNil(firstDeviceId)

        _ = await Amplify.Auth.signOut()

        let result = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userSRP
        )
        XCTAssertTrue(result.isSignedIn)

        let devicesAfterSecond = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterSecond.count, 1,
            "Should still have 1 device after re-sign-in, not a duplicate")
        XCTAssertEqual(devicesAfterSecond.first?.id, firstDeviceId,
            "Device ID should be the same across sign-out/sign-in")
    }

    // MARK: - Cross-flow tests (the actual bug scenario)

    /// Test that device ID persists when switching from USER_PASSWORD_AUTH to USER_SRP_AUTH
    ///
    /// - Given: A user who signed in with USER_PASSWORD_AUTH and called rememberDevice
    /// - When: The user signs out and signs back in with USER_SRP_AUTH
    /// - Then: fetchDevices should return the same device ID, not a new one
    func testDeviceKeyPersistsFromUserPasswordToUserSRP() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        _ = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )

        // First sign-in: USER_PASSWORD_AUTH
        let firstResult = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userPassword
        )
        XCTAssertTrue(firstResult.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()
        let devicesAfterFirst = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterFirst.count, 1,
            "Should have exactly 1 device after USER_PASSWORD_AUTH sign-in")
        let firstDeviceId = devicesAfterFirst.first?.id
        XCTAssertNotNil(firstDeviceId)

        _ = await Amplify.Auth.signOut()

        // Second sign-in: USER_SRP_AUTH (different flow)
        let secondResult = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userSRP
        )
        XCTAssertTrue(secondResult.isSignedIn)

        let devicesAfterSecond = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterSecond.count, 1,
            "Switching from USER_PASSWORD_AUTH to USER_SRP_AUTH should NOT create a new device")
        XCTAssertEqual(devicesAfterSecond.first?.id, firstDeviceId,
            "Device ID must be identical after switching auth flows")
    }

    /// Test that device ID persists when switching from USER_SRP_AUTH to USER_PASSWORD_AUTH
    ///
    /// - Given: A user who signed in with USER_SRP_AUTH and called rememberDevice
    /// - When: The user signs out and signs back in with USER_PASSWORD_AUTH
    /// - Then: fetchDevices should return the same device ID, not a new one
    func testDeviceKeyPersistsFromUserSRPToUserPassword() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        _ = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )

        // First sign-in: USER_SRP_AUTH
        let firstResult = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userSRP
        )
        XCTAssertTrue(firstResult.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()
        let devicesAfterFirst = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterFirst.count, 1,
            "Should have exactly 1 device after USER_SRP_AUTH sign-in")
        let firstDeviceId = devicesAfterFirst.first?.id
        XCTAssertNotNil(firstDeviceId)

        _ = await Amplify.Auth.signOut()

        // Second sign-in: USER_PASSWORD_AUTH (different flow)
        let secondResult = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userPassword
        )
        XCTAssertTrue(secondResult.isSignedIn)

        let devicesAfterSecond = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterSecond.count, 1,
            "Switching from USER_SRP_AUTH to USER_PASSWORD_AUTH should NOT create a new device")
        XCTAssertEqual(devicesAfterSecond.first?.id, firstDeviceId,
            "Device ID must be identical after switching auth flows")
    }

    /// Test that device ID persists through multiple alternating auth flow changes
    ///
    /// - Given: A user who signed in with USER_PASSWORD_AUTH and called rememberDevice
    /// - When: The user alternates between USER_SRP_AUTH and USER_PASSWORD_AUTH over 4 cycles
    /// - Then: fetchDevices should always return the same single device
    func testDeviceKeyStableAcrossAlternatingAuthFlows() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        _ = try await AuthSignInHelper.signUpUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )

        // Initial sign-in with USER_PASSWORD_AUTH
        let initialResult = try await signInAndWait(
            username: username,
            password: password,
            authFlowType: .userPassword
        )
        XCTAssertTrue(initialResult.isSignedIn)

        _ = try await Amplify.Auth.rememberDevice()
        let initialDevices = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(initialDevices.count, 1)
        let originalDeviceId = initialDevices.first?.id
        XCTAssertNotNil(originalDeviceId)

        // Alternate flows: SRP → Password → SRP → Password
        let flows: [AuthFlowType] = [.userSRP, .userPassword, .userSRP, .userPassword]
        for (index, flow) in flows.enumerated() {
            _ = await Amplify.Auth.signOut()

            let result = try await signInAndWait(
                username: username,
                password: password,
                authFlowType: flow
            )
            XCTAssertTrue(result.isSignedIn)

            let devices = try await Amplify.Auth.fetchDevices()
            XCTAssertEqual(devices.count, 1,
                "Cycle \(index + 1) (\(flow)): device count should remain 1, got \(devices.count)")
            XCTAssertEqual(devices.first?.id, originalDeviceId,
                "Cycle \(index + 1) (\(flow)): device ID should remain the same")
        }
    }
}

private extension AuthFlowType {
    var description: String {
        switch self {
        case .userSRP: return "USER_SRP_AUTH"
        case .userPassword: return "USER_PASSWORD_AUTH"
        case .custom: return "CUSTOM_AUTH"
        default: return "OTHER"
        }
    }
}
