//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthConfirmResetPasswordTests: AWSAuthBaseTest {
    
    override func setUp() {
        super.setUp()
        initializeAmplify()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await Amplify.reset()
        sleep(2)
    }
    
    /// Test if confirmResetPassword returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke confirmResetPassword with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUserNotFoundResetPassword() {
        let confirmResetPasswordExpectation = expectation(description: "Received event result from resetPassword")
        _ = Amplify.Auth.confirmResetPassword(for: "user-non-exists", with: "password", confirmationCode: "123", options: nil) { result in
            switch result {
            case .success:
                XCTFail("resetPassword with non existing user should not return result")
            case .failure(let error):
                guard let cognitoError = error.underlyingError as? AWSCognitoAuthError,
                      case .userNotFound = cognitoError else {
                          print(error)
                          XCTFail("Should return userNotFound")
                          return
                      }
                confirmResetPasswordExpectation.fulfill()
            }
        }
        wait(for: [confirmResetPasswordExpectation], timeout: networkTimeout)
    }
    
    /// Calling cancel in confirmResetPassword operation should cancel
    ///
    /// - Given: A valid username
    /// - When:
    ///    - I invoke confirmResetPassword with the username and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelResetPassword() {
        let username = "integTest\(UUID().uuidString)"
        
        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.confirmResetPassword(for: username, with: "password", confirmationCode: "123", options: nil) { result in
            operationExpectation.fulfill()
            XCTFail("Received result \(result)")
        }
        XCTAssertNotNil(operation, "confirmResetPassword operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
