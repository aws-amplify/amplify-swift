//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

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

    /// Test if forgetDevice returns deviceNotTracked error for a unknown device
    ///
    /// - Given: A test with the device not tracked
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a deviceNotTracked error.
    ///
    func testForgetDeviceWithUnknowdevice() {
        let forgetDeviceExpectation = expectation(description: "Received event result from forgetDevice")
        _ = Amplify.Auth.forgetDevice { result in
            switch result {
            case .success:
                XCTFail("Confirm signUp with non existing user should not return result")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                      case .deviceNotTracked = cognitoError else {
                    XCTFail("Should return deviceNotTracked")
                    return
                }

            }
            forgetDeviceExpectation.fulfill()
        }
        wait(for: [forgetDeviceExpectation], timeout: networkTimeout)
    }

}
