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

class AuthRememberDeviceTests: AWSAuthBaseTest {

    var unsubscribeToken: UnsubscribeToken!

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        AuthSessionHelper.clearSession()
        sleep(2)
    }

    /// Calling remember device should return a successful result
    ///
    /// - Given: A valid username is registered and sign in
    /// - When:
    ///    - I invoke rememberDevice followed by fetchDevices
    /// - Then:
    ///    - I should get a successful result for rememberDevice and fetchDevices should
    ///      contain the deviceKey used in rememberDevice
    ///
    func testSuccessfulRememberDevice() async throws {

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

        _ = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail)
        await waitForExpectations([signInExpectation], timeout: networkTimeout)

        _ = try await Amplify.Auth.rememberDevice()

        let devices = try await Amplify.Auth.fetchDevices()
        XCTAssertNotNil(devices)
        XCTAssertGreaterThan(devices.count, 0)
    }
}
