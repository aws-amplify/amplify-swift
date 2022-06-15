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
    
    /// Test fetching the user's email attribute.
    ///
    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.fetchUserAttributes
    /// - Then:
    ///    - The request should be successful and the email attribute should have the correct value
    ///
    func testSuccessfulFetchAttribute() throws {
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

        let fetchUserAttributeExpectation = expectation(description: "Fetch User Attribute operation should complete")
        
        _ = Amplify.Auth.fetchUserAttributes(listener: { result in
            switch result {
            case .success(let attributes):
                if let emailAttribute = attributes.filter({ $0.key == .email }).first {
                    XCTAssertEqual(emailAttribute.value, self.defaultTestEmail)
                } else {
                    XCTFail("Email attribute not found")
                }
                fetchUserAttributeExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch user attribute with \(error)")
            }
        })
        wait(for: [fetchUserAttributeExpectation], timeout: networkTimeout)
    }
    
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
        let updatedEmail = "\(username)@amazon.com"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let updateExpectation = expectation(description: "Update operation should complete")
        let pluginOptions = AWSUpdateUserAttributeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        _ = Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: updatedEmail), options: options) { result in
            switch result {
            case .success:
                updateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to update user attribute with \(error)")
            }
        }
        wait(for: [updateExpectation], timeout: networkTimeout)
        
        let fetchUserAttributeExpectation = expectation(description: "Fetch User Attribute operation should complete")
        
        _ = Amplify.Auth.fetchUserAttributes(listener: { result in
            switch result {
            case .success(let attributes):
                if let emailAttribute = attributes.filter({ $0.key == .email }).first {
                    XCTAssertEqual(emailAttribute.value, updatedEmail)
                } else {
                    XCTFail("Email attribute not found")
                }
                fetchUserAttributeExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch user attribute with \(error)")
            }
        })
        wait(for: [fetchUserAttributeExpectation], timeout: networkTimeout)
    }
    
    
    /// Test updating the user's email and name attributes.
    /// Internally, Cognito's `UpdateUserAttributes` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_UpdateUserAttributes.html
    /// for more details.
    ///
    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.update with email and name attribute
    /// - Then:
    ///    - The request should be successful and the email, name specified should receive a confirmation code
    ///
    func testSuccessfulUpdateOfMultipleAttributes() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedEmail = "\(username)@amazon.com"
        let updatedName = "Name\(UUID().uuidString)"

        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let updateExpectation = expectation(description: "Update operation should complete")
        let pluginOptions = AWSUpdateUserAttributesOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributesRequest.Options(pluginOptions: pluginOptions)
        let attributes = [
            AuthUserAttribute(.email, value: updatedEmail),
            AuthUserAttribute(.name, value: updatedName)
        ]
        _ = Amplify.Auth.update(
            userAttributes: attributes, options: options) { result in
            switch result {
            case .success:
                updateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to update user attribute with \(error)")
            }
        }
        wait(for: [updateExpectation], timeout: networkTimeout)
        
        let fetchUserAttributeExpectation = expectation(description: "Fetch User Attribute operation should complete")
        
        _ = Amplify.Auth.fetchUserAttributes(listener: { result in
            switch result {
            case .success(let attributes):
                if let emailAttribute = attributes.filter({ $0.key == .email }).first {
                    XCTAssertEqual(emailAttribute.value, updatedEmail)
                } else {
                    XCTFail("Email attribute not found")
                }
                
                if let emailAttribute = attributes.filter({ $0.key == .name }).first {
                    XCTAssertEqual(emailAttribute.value, updatedName)
                } else {
                    XCTFail("Email attribute not found")
                }
                fetchUserAttributeExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to fetch user attribute with \(error)")
            }
        })
        wait(for: [fetchUserAttributeExpectation], timeout: networkTimeout)
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
    func testSuccessfulResendConfirmationCodeWithUpdatedEmail() throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedEmail = "\(username)@amazon.com"
        
        let signInExpectation = expectation(description: "SignIn operation should complete")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: defaultTestEmail) { didSucceed, error in
            signInExpectation.fulfill()
            XCTAssertTrue(didSucceed, "SignIn operation failed - \(String(describing: error))")
        }
        wait(for: [signInExpectation], timeout: networkTimeout)

        let updateExpectation = expectation(description: "Update operation should complete")

        _ = Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: updatedEmail)) { result in
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
