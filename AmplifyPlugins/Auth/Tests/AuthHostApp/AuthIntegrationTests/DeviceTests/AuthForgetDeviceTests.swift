//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthForgetDeviceTests: AWSAuthBaseTest {

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

//    /// TODO: Verify this test when an API for deviceKey is implemented
//    /// Calling forget device should return a successful result
//    ///
//    /// - Given: A valid username is registered and sign in
//    /// - When:
//    ///    - I invoke rememberDevice, followed by forgetDevice and fetchDevice
//    /// - Then:
//    ///    - I should get a successful result for forgetDevice and rememberDevice and fetchDevices should
//    ///      return empty result
//    ///
//    func testSuccessfulForgetDevice() {
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
//        // forget device
//        let forgetDeviceExpectation = expectation(description: "Received result from forgetDevice")
//        _ = Amplify.Auth.forgetDevice { result in
//            switch result {
//            case .success:
//                forgetDeviceExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("error forgetting device \(error)")
//            }
//        }
//        wait(for: [forgetDeviceExpectation], timeout: networkTimeout)
//
//
//        // fetch devices
//        let fetchDevicesExpectation = expectation(description: "Received result from fetchDevices")
//        _ = Amplify.Auth.fetchDevices { result in
//            switch result {
//            case .success(let devices):
//                XCTAssertNotNil(devices)
//                XCTAssertEqual(devices.count, 0)
//                fetchDevicesExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("error fetching devices \(error)")
//            }
//        }
//        wait(for: [fetchDevicesExpectation], timeout: networkTimeout)
//    }

    /// Calling cancel in forgetDevice operation should cancel
    ///
    /// - Given: A valid user session
    /// - When:
    ///    - I invoke forgetDevice and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelForgetDevice() {
        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.forgetDevice { result in
            operationExpectation.fulfill()
            XCTFail("Received result \(result)")
        }
        XCTAssertNotNil(operation, "forgetDevice operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
