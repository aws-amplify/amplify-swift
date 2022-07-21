//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthFetchDeviceTests: AWSAuthBaseTest {
    
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

    /// Calling fetch devices with a user signed in should return a successful result
    ///
    /// - Given: A valid username is registered and sign in - no device is remembered
    /// - When:
    ///    - I invoke fetchDevices with the username
    /// - Then:
    ///    - I should get a successful result with empty devices list
    ///
    func testSuccessfulFetchDevices() {
        
        // register a user and signin
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn event should be fired")
        
        unsubscribeToken = Amplify.Hub.listen(to: .auth) { payload in
            switch payload.eventName {
            case HubPayload.EventName.Auth.signedIn:
                signInExpectation.fulfill()
            default:
                break
            }
        }

        AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail) { _, error in
                if let unwrappedError = error {
                    XCTFail("Unable to sign in with error: \(unwrappedError)")
                }
            }
        wait(for: [signInExpectation], timeout: networkTimeout)
        
        // fetch devices
        let fetchDevicesExpectation = expectation(description: "Received result from fetchDevices")
        _ = Amplify.Auth.fetchDevices { result in
            switch result {
            case .success(let devices):
                XCTAssertNotNil(devices)
                XCTAssertEqual(devices.count, 0)
                fetchDevicesExpectation.fulfill()
            case .failure(let error):
                XCTFail("error fetching devices \(error)")
            }
        }
        wait(for: [fetchDevicesExpectation], timeout: networkTimeout)
    }
    
    
    /// Calling cancel in fetch devices operation should cancel
    ///
    /// - Given: A valid username
    /// - When:
    ///    - I invoke fetchDevices with the username and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelFetchDevices() {
        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.fetchDevices { result in
            operationExpectation.fulfill()
            XCTFail("Received result \(result)")
        }
        XCTAssertNotNil(operation, "fetchDevices operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
