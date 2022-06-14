//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthConfirmSignUpTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        Amplify.Auth.signOut { _ in }
    }

    override func tearDown() async throws {
        super.tearDown()
        await Amplify.reset()
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

    /// Test confirmSignUp return validation error
    ///
    /// - Given: An invalid input to confirmSignUp like empty code
    /// - When:
    ///    - I invoke confirmSignUp with empty code
    /// - Then:
    ///    - I should get validation error.
    ///
    func testConfirmSignUpValidation() {
        let username = "integTest\(UUID().uuidString)"

        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.confirmSignUp(for: username,
                                                   confirmationCode: "") { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("""
            confirmSignUp with validation error should not succeed
            """)
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should return validation error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "confirmSignUp operations should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Calling cancel in confirmSignUp operation should cancel
    ///
    /// - Given: A valid username and code
    /// - When:
    ///    - I invoke confirmSignUp with the username and confirmatioCode and then call cancel
    /// - Then:
    ///    - I should not get any result back
    ///
    func testCancelConfirmSignUpOperation() {
        let username = "integTest\(UUID().uuidString)"

        let operationExpectation = expectation(description: "Operation should not complete")
        operationExpectation.isInverted = true
        let operation = Amplify.Auth.confirmSignUp(for: username, confirmationCode: "123") { result in
            operationExpectation.fulfill()
            XCTFail("Received result \(result)")
        }
        XCTAssertNotNil(operation, "confirmSignUp operations should not be nil")
        operation.cancel()
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
