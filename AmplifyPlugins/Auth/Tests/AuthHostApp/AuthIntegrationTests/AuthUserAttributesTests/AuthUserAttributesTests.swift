//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import XCTest
@testable import Amplify

class AuthUserAttributesTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test fetching the user's email attribute.
    ///
    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.fetchUserAttributes
    /// - Then:
    ///    - The request should be successful and the email attribute should have the correct value
    ///
    func testSuccessfulFetchAttribute() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let attributes = try await Amplify.Auth.fetchUserAttributes()
        if let emailAttribute = attributes.filter({ $0.key == .email }).first {
            XCTAssertEqual(emailAttribute.value, defaultTestEmail)
        } else {
            XCTFail("Email attribute not found")
        }
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
    func testSuccessfulUpdateEmailAttribute() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedEmail = "\(username)@amazon.com"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let pluginOptions = AWSAuthUpdateUserAttributeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        _ = try await Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: updatedEmail), options: options)

        let updatedAttributes = try await Amplify.Auth.fetchUserAttributes()
        if let emailAttribute = updatedAttributes.filter({ $0.key == .email }).first {
            XCTAssertEqual(emailAttribute.value, updatedEmail)
        } else {
            XCTFail("Email attribute not found")
        }
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
    func testSuccessfulUpdateOfMultipleAttributes() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedFamilyName = "\(username)@amazon.com"
        let updatedName = "Name\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let pluginOptions = AWSAuthUpdateUserAttributesOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributesRequest.Options(pluginOptions: pluginOptions)
        let attributes = [
            AuthUserAttribute(.familyName, value: updatedFamilyName),
            AuthUserAttribute(.name, value: updatedName)
        ]
        _ = try await Amplify.Auth.update(userAttributes: attributes, options: options)

        let updatedAttributes = try await Amplify.Auth.fetchUserAttributes()
        if let familyNameAttribute = updatedAttributes.filter({ $0.key == .familyName }).first {
            XCTAssertEqual(familyNameAttribute.value, updatedFamilyName)
        } else {
            XCTFail("family name attribute not found")
        }

        if let nameAttribute = attributes.filter({ $0.key == .name }).first {
            XCTAssertEqual(nameAttribute.value, updatedName)
        } else {
            XCTFail("name attribute not found")
        }
    }

    /// - Given: A confirmed user
    /// - When:
    ///    - I invoke Amplify.Auth.update with email attribute and then confirm the email attribute with an invalid code
    /// - Then:
    ///    - The confirmation request should fail with a Auth service error
    ///
    func testSuccessfulUserAttributesConfirmation() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedEmail = "\(username)@amazon.com"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let pluginOptions = AWSAuthUpdateUserAttributeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        let updateResult = try await Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: updatedEmail), options: options)

        switch updateResult.nextStep {
        case .confirmAttributeWithCode(let deliveryDetails, let info):
            print("Confirm the attribute with details send to - \(deliveryDetails) \(String(describing: info))")
        case .done:
            print("Update completed")
        }

        do {
            try await Amplify.Auth.confirm(userAttribute: .email, confirmationCode: "123")
            XCTFail("User attribute confirmation unexpectedly succeeded")
        } catch {
            guard case AuthError.service(_, _, _) = error else {
                XCTFail("Should throw service error")
                return
            }
        }
    }

    /// Test resending code for the user's updated email attribute.
    /// Internally, Cognito's `GetUserAttributeVerificationCode` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_GetUserAttributeVerificationCode.html
    /// for more details.
    ///
    /// - Given: A confirmed user, with email added to the user's attributes (sending first confirmation code)
    /// - When:
    ///    - I invoke Amplify.Auth.sendVerificationCode for email
    /// - Then:
    ///    - The request should be successful and the email specified should receive a second confirmation code
    ///
    func testSuccessfulSendVerificationCodeWithUpdatedEmail() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"
        let updatedEmail = "\(username)@amazon.com"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        _ = try await Amplify.Auth.update(userAttribute: AuthUserAttribute(.email, value: updatedEmail))
        let pluginOptions = AWSSendUserAttributeVerificationCodeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthSendUserAttributeVerificationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await Amplify.Auth.sendVerificationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test resending code for the user's updated email attribute.
    /// Internally, Cognito's `GetUserAttributeVerificationCode` API will be called with metadata as clientMetadata.
    /// The configured lambda trigger will invoke the custom message lambda with the client metadata payload. See
    /// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_GetUserAttributeVerificationCode.html
    /// for more details.
    ///
    /// - Given: A confirmed user, with email added to the user's attributes (sending first confirmation code)
    /// - When:
    ///    - I invoke Amplify.Auth.sendVerificationCode for email
    /// - Then:
    ///    - The request should be successful and the email specified should receive a second confirmation code
    ///
    func testSuccessfulSendVerificationCode() async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        let pluginOptions = AWSSendUserAttributeVerificationCodeOptions(metadata: ["mydata": "myvalue"])
        let options = AuthSendUserAttributeVerificationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await Amplify.Auth.sendVerificationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test changing/updating users password.
    ///
    /// - Given: A confirmed user signed In
    /// - When:
    ///    - I invoke Amplify.Auth.update(oldPassword:, updatedPassword:)
    /// - Then:
    ///    - The request should be successful and the password should be updated
    ///
    func testSuccessfulChangePassword() async throws {
        let username = "integTest\(UUID().uuidString)"
        let oldPassword = "P123@\(UUID().uuidString)"
        let updatedPassword = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: oldPassword,
            email: defaultTestEmail
        )
        XCTAssertTrue(didSucceed, "SignIn operation failed")

        try await Amplify.Auth.update(oldPassword: oldPassword, to: updatedPassword)

        let attributes = try await Amplify.Auth.fetchUserAttributes()
        if let emailAttribute = attributes.filter({ $0.key == .email }).first {
            XCTAssertEqual(emailAttribute.value, defaultTestEmail)
        } else {
            XCTFail("Email attribute not found")
        }
    }
}
