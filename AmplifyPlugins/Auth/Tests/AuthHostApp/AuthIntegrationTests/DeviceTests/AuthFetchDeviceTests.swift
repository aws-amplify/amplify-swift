//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AmplifyAsyncTesting

class AuthFetchDeviceTests: AWSAuthBaseTest {

    var unsubscribeToken: UnsubscribeToken!

    override func setUp() async throws {
        throw XCTSkip("Device Tracking is currently disabled. Remove once a new configuration is created for V2")
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Calling fetch devices with a user signed in should return a successful result
    ///
    /// - Given: A valid username is registered and sign in - no device is remembered
    /// - When:
    ///    - I invoke fetchDevices with the username
    /// - Then:
    ///    - I should get a successful result with empty devices list
    ///
    func testSuccessfulFetchDevices() async throws {

        // register a user and signin
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = asyncExpectation(description: "SignIn event should be fired")

        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                Task {
                    await signInExpectation.fulfill()
                }

            default:
                break
            }
        }

        do {
            _ = try await AuthSignInHelper.registerAndSignInUser(
                username: username,
                password: password,
                email: defaultTestEmail)
        } catch {
            print(error)
        }
        
        await waitForExpectations([signInExpectation], timeout: networkTimeout)

        // fetch devices
        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertNotNil(devices)
        XCTAssertEqual(devices.count, 1)
    }
}
