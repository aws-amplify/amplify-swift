//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthSignUpTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
    }

    override func tearDown() {
        super.tearDown()
        Amplify.reset()
        sleep(2)
    }

    /// Test if confirmSignUp returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke confirmSignUp with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUserNotFoundConfirmSignUp() {
        let confirmSignUpExpectation = expectation(description: "Received event result from confirmSignUp")
        _ = Amplify.Auth.confirmSignUp(for: "user-non-exists", confirmationCode: "232") { result in
            switch result {
            case .success:
                XCTFail("Confirm signUp with non existing user should not return result")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                    case .userNotFound = cognitoError else {
                        XCTFail("Should return userNotFound")
                        return
                }

            }
            confirmSignUpExpectation.fulfill()
        }
        wait(for: [confirmSignUpExpectation], timeout: networkTimeout)
    }

    /// Test if resendSignUpCode returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke resendSignUpCode with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUsertNotFoundResendSignUpCode() {
        let resendSignUpCodeExpectation = expectation(description: "Received event result from resendSignUpCode")
        _ = Amplify.Auth.resendSignUpCode(for: "user-non-exists") { result in
            switch result {
            case .success:
                XCTFail("resendSignUpCode with non existing user should not return result")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                    case .userNotFound = cognitoError else {
                        XCTFail("Should return userNotFound")
                        return
                }

            }
            resendSignUpCodeExpectation.fulfill()
        }
        wait(for: [resendSignUpCodeExpectation], timeout: networkTimeout)
    }
}
