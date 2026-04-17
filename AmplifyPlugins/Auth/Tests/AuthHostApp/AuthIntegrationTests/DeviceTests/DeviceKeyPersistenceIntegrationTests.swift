//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

/// Integration tests for device key persistence across sign-in/sign-out cycles.
///
/// These tests verify that once a device is registered via rememberDevice(),
/// subsequent sign-in attempts reuse the same device ID rather than generating
/// a new one. This is critical for flows where external systems (e.g., payment
/// processors) link data to Cognito device IDs.
///
/// Prerequisites:
/// - Cognito User Pool with Device Tracking set to "Always Remember"
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

    /// Test that device ID persists across sign-out and sign-in cycles
    ///
    /// - Given: A registered user who has called rememberDevice
    /// - When: The user signs out and signs back in with the same credentials
    /// - Then: fetchDevices should return the same device ID (no duplicate)
    func testDeviceKeyPersistsAcrossSignOutSignIn() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "First sign in")
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            if payload.eventName == HubPayload.EventName.Auth.signedIn {
                signInExpectation.fulfill()
            }
        }

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        await fulfillment(of: [signInExpectation], timeout: networkTimeout)
        Amplify.Hub.removeListener(unsubscribeToken)

        _ = try await Amplify.Auth.rememberDevice()
        let devicesAfterFirst = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterFirst.count, 1, "Should have exactly 1 device after first sign-in")
        let firstDeviceId = devicesAfterFirst.first?.id

        _ = await Amplify.Auth.signOut()

        let reSignInExpectation = expectation(description: "Re-sign in")
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            if payload.eventName == HubPayload.EventName.Auth.signedIn {
                reSignInExpectation.fulfill()
            }
        }

        let result = try await AuthSignInHelper.signInUser(username: username, password: password)
        XCTAssertTrue(result.isSignedIn)
        await fulfillment(of: [reSignInExpectation], timeout: networkTimeout)
        Amplify.Hub.removeListener(unsubscribeToken)

        let devicesAfterSecond = try await Amplify.Auth.fetchDevices()
        XCTAssertEqual(devicesAfterSecond.count, 1,
            "Should still have 1 device after re-sign-in, not a duplicate")
        XCTAssertEqual(devicesAfterSecond.first?.id, firstDeviceId,
            "Device ID should be the same across sign-out/sign-in")
    }

    /// Test that device count does not grow with repeated sign-in/sign-out cycles
    ///
    /// - Given: A registered user who has called rememberDevice
    /// - When: The user performs multiple sign-out/sign-in cycles
    /// - Then: fetchDevices should always return the same single device
    func testDeviceCountStableAcrossMultipleSignInCycles() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "Initial sign in")
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            if payload.eventName == HubPayload.EventName.Auth.signedIn {
                signInExpectation.fulfill()
            }
        }

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        await fulfillment(of: [signInExpectation], timeout: networkTimeout)
        Amplify.Hub.removeListener(unsubscribeToken)

        _ = try await Amplify.Auth.rememberDevice()

        let initialDevices = try await Amplify.Auth.fetchDevices()
        let initialDeviceId = initialDevices.first?.id
        XCTAssertEqual(initialDevices.count, 1)

        for cycle in 1...3 {
            _ = await Amplify.Auth.signOut()

            let cycleExpectation = expectation(description: "Sign in cycle \(cycle)")
            unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
                if payload.eventName == HubPayload.EventName.Auth.signedIn {
                    cycleExpectation.fulfill()
                }
            }

            let result = try await AuthSignInHelper.signInUser(
                username: username,
                password: password
            )
            XCTAssertTrue(result.isSignedIn)
            await fulfillment(of: [cycleExpectation], timeout: networkTimeout)
            Amplify.Hub.removeListener(unsubscribeToken)

            let devices = try await Amplify.Auth.fetchDevices()
            XCTAssertEqual(devices.count, 1,
                "Cycle \(cycle): device count should remain 1, got \(devices.count)")
            XCTAssertEqual(devices.first?.id, initialDeviceId,
                "Cycle \(cycle): device ID should remain the same")
        }
    }
}
