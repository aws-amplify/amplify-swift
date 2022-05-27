//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthUserAttributesTests: AWSAuthBaseTest {

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() {
        super.tearDown()
        AuthSessionHelper.clearSession()
        Amplify.reset()
    }
    
    /*
    /// Test updating the user's email attribute.
    /// Internally, Cognito's `UpdateUserAttributes` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_UpdateUserAttributes.html
    /// for more details.
    ///
    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.update with email attribute
    /// - Then:
    ///    - The request should be successful and the email specified should receive a confirmation code
    ///
    func testSuccessfulUpdateEmailAttribute() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let updateExpectation = expectation(description: "Update operation should complete")
        let pluginOptions = AWSUpdateUserAttributeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        _ = Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: email), options: options) { result in
            switch result {
            case .success:
                updateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to update user attribute with \(error)")
            }
        }
        wait(for: [updateExpectation], timeout: networkTimeout)
    }

    /// Test resending code for the user's updated email attribute.
    /// Internally, Cognito's `GetUserAttributeVerificationCode` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_GetUserAttributeVerificationCode.html
    /// for more details.
    ///
    /// - Given: A confirmed user, with email added to the user's attributes (sending first confirmation code)
    /// - When:
    ///    - I invoke Amplify.Auth.resendConfirmationCode for email
    /// - Then:
    ///    - The request should be successful and the email specified should receive a second confirmation code
    ///
    func testSuccessfulResendConfirmationCode() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let updateExpectation = expectation(description: "Update operation should complete")

        _ = Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: email2)) { result in
            switch result {
            case .success:
                updateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to update user attribute with \(error)")
            }
        }
        wait(for: [updateExpectation], timeout: networkTimeout)

        let resendExpectation = expectation(description: "ResendConfirmationCode operation should complete")

        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = Amplify.Auth.resendConfirmationCode(for: .email, options: options) { result in
            switch result {
            case .success(let deliveryDetails):
                print("Resend code send to - \(deliveryDetails)")
                resendExpectation.fulfill()
            case .failure(let error):
                print("Resend code failed with error \(error)")
            }
        }
        wait(for: [resendExpectation], timeout: networkTimeout)
    }
    */

    
    
    /// Test resending code for the user's updated email attribute.
    /// Internally, Cognito's `GetUserAttributeVerificationCode` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_GetUserAttributeVerificationCode.html
    /// for more details.
    ///
    /// - Given: A confirmed user, with email added to the user's attributes (sending first confirmation code)
    /// - When:
    ///    - I invoke Amplify.Auth.resendConfirmationCode for email
    /// - Then:
    ///    - The request should be successful and the email specified should receive a second confirmation code
    ///
    func testSuccessfulResendConfirmationCode() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let resendExpectation = expectation(description: "ResendConfirmationCode operation should complete")

        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = Amplify.Auth.resendConfirmationCode(for: .email, options: options) { result in
            switch result {
            case .success(let deliveryDetails):
                print("Resend code send to - \(deliveryDetails)")
                resendExpectation.fulfill()
            case .failure(let error):
                print("Resend code failed with error \(error)")
            }
        }
        wait(for: [resendExpectation], timeout: networkTimeout)
    }
}
