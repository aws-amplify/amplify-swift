//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthResendSignUpCodeTests: AWSAuthBaseTest {

    override func setUpWithError() throws {
        try initializeAmplify()
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        sleep(2)
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

    /// Calling cancel in resendSignUpCode operation should cancel
    ///
    /// - Given: A valid username
    /// - When:
    ///    - I invoke resendSignUpCode with the username and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelResendSignUpCodeOperation() {
        let username = "integTest\(UUID().uuidString)"

        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.resendSignUpCode(for: username) { result in
            operationExpectation.fulfill()
            XCTFail("Received result \(result)")
        }
        XCTAssertNotNil(operation, "resendSignUpCode operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
