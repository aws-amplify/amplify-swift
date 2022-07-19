//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AmplifyTestCommon
import AWSCognitoAuthPlugin
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

class AuthDeviceOperationTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    /// Test if forgetDevice returns deviceNotTracked error for a signed out user
    ///
    /// - Given: A test with the user not signed in
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a notSignedIn error.
    ///
    func testForgetDeviceWithSignedOutUser() {
        let forgetDeviceExpectation = expectation(description: "Received event result from forgetDevice")
        _ = Amplify.Auth.forgetDevice { result in
            forgetDeviceExpectation.fulfill()
            switch result {
            case .success:
                XCTFail("Forget device with signed out user should not return success")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSMobileClientError,
                      case .notSignedIn = cognitoError else {
                    XCTFail("Should return notSignedIn")
                    return
                }
            }
        }
        wait(for: [forgetDeviceExpectation], timeout: networkTimeout)
    }

    /// Test if forgetDevice returns deviceNotTracked error for a unknown device
    ///
    /// - Given: A test with a device not tracked
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a deviceNotTracked error.
    ///
    func testForgetDeviceWithUntrackedDevice() {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username, password: password,
                                               email: email) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let user = Amplify.Auth.getCurrentUser()
        XCTAssertNotNil(user)

        let forgetDeviceExpectation = expectation(description: "Received event result from forgetDevice")
        _ = Amplify.Auth.forgetDevice { result in
            forgetDeviceExpectation.fulfill()
            switch result {
            case .success:
                XCTFail("Forget device with untracked device should not return result")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                      case .deviceNotTracked = cognitoError else {
                    XCTFail("Should return deviceNotTracked")
                    return
                }

            }
        }
        wait(for: [forgetDeviceExpectation], timeout: networkTimeout)
    }

}
