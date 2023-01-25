//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AmplifyTestCommon

class AuthUserTests: AWSAuthBaseTest {

    override func setUpWithError() throws {
        try initializeAmplify()
    }

    override func tearDownWithError() throws {
        Amplify.reset()
        sleep(2)
    }

    /// Test retreiving user in a signedout state
    ///
    /// - Given: Amplify Auth plugin in signedout state
    /// - When:
    ///    - I retreive the current user
    /// - Then:
    ///    - I should get a nil object
    ///
    func testUserInSignedOut() {
        let user = Amplify.Auth.getCurrentUser()
        XCTAssertNil(user, "In signedout state the user should be nil")
    }

    /// Test retreiving user in a signedIn state
    ///
    /// - Given: Amplify Auth plugin in signedIn state
    /// - When:
    ///    - I retreive the current user
    /// - Then:
    ///    - I should get a valid user
    ///
    func testUserInSignedIn() {

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
        XCTAssertNotNil(user, "In signedIn state the user should be nil")
    }

    /// Test attribute fetch in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testFetchUserAttributesSignedOut() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.fetchUserAttributes { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test attribute update in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke update(userAttribtue:)
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testUpdateUserAttributeSignedOut() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: "xc@email.com")) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test attribute update as a list in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke update(userAttribtues:)
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testUpdateUserAttributeListSignedOut() {
        let attributes = [AuthUserAttribute(.email, value: "xc@email.com"),
                          AuthUserAttribute(.phoneNumber, value: "123")]
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.update(userAttributes: attributes) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test resend confirmation code for attribute in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testResendAttributeCodeSignedOut() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.resendConfirmationCode(for: .email) { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test confirm attribute in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke confirm(userAttribute: )
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testConfirmAttributeCodeSignedOut() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.confirm(userAttribute: .email, confirmationCode: "123") { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }

    /// Test change password in signedout state
    ///
    /// - Given: Amplify auth plugin in signedout state
    /// - When:
    ///    - I invoke update(oldPassword:to:)
    /// - Then:
    ///    - I should get a .signedOut error
    ///
    func testChangePasswordSignedOut() {
        let operationExpectation = expectation(description: "Operation should complete")
        let operation = Amplify.Auth.update(oldPassword: "somepassword",
                                            to: "newpassword") { result in
            defer {
                operationExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Attribute apis should not succeed on a signedOut state")
            case .failure(let error):
                guard case .signedOut = error else {
                    XCTFail("Should return signedOut error")
                    return
                }
            }
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [operationExpectation], timeout: networkTimeout)
    }
}
