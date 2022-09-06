//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

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

/// TODO: Verify this test when an API for deviceKey is implemented
//    /// Calling remember device should return a successful result
//    ///
//    /// - Given: A valid username is registered and sign in
//    /// - When:
//    ///    - I invoke rememberDevice followed by fetchDevices
//    /// - Then:
//    ///    - I should get a successful result for rememberDevice and fetchDevices should
//    ///      contain the deviceKey used in rememberDevice
//    ///
//    func testSuccessfulRememberDevice() {
//
//        // register a user and signin
//        let username = "integTest\(UUID().uuidString)"
//        let password = "P123@\(UUID().uuidString)"
//
//        let signInExpectation = expectation(description: "SignIn event should be fired")
//
//        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
//            switch payload.eventName {
//            case HubPayload.EventName.Auth.signedIn:
//                signInExpectation.fulfill()
//            default:
//                break
//            }
//        }
//
//        AuthSignInHelper.registerAndSignInUser(
//            username: username,
//            password: password,
//            email: defaultTestEmail) { _, error in
//                if let unwrappedError = error {
//                    XCTFail("Unable to sign in with error: \(unwrappedError)")
//                }
//            }
//        wait(for: [signInExpectation], timeout: networkTimeout)
//
//        // remember device
//        let rememberDeviceExpectation = expectation(description: "Received result from rememberDevice")
//        _ = Amplify.Auth.rememberDevice { result in
//            switch result {
//            case .success:
//                rememberDeviceExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("error remembering device \(error)")
//            }
//        }
//        wait(for: [rememberDeviceExpectation], timeout: networkTimeout)
//
//
//        // fetch devices
//        let fetchDevicesExpectation = expectation(description: "Received result from fetchDevices")
//        _ = Amplify.Auth.fetchDevices { result in
//            switch result {
//            case .success(let devices):
//                XCTAssertNotNil(devices)
//                XCTAssertGreaterThan(devices.count, 0)
//                XCTAssertTrue(devices.contains { device in
//                    device.id == deviceKey
//                })
//                fetchDevicesExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("error fetching devices \(error)")
//            }
//        }
//        wait(for: [fetchDevicesExpectation], timeout: networkTimeout)
//    }
}
