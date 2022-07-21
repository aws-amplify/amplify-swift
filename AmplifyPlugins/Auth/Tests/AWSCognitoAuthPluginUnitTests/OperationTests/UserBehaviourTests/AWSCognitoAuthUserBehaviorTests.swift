//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

class AWSCognitoAuthUserBehaviorTests: BasePluginTest {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeVerificationCodeOutputResponse: { _ in
                GetUserAttributeVerificationCodeOutputResponse()
            },
            mockGetUserAttributeResponse: { _ in
                GetUserOutputResponse()
            },
            mockUpdateUserAttributeResponse: { _ in
                UpdateUserAttributesOutputResponse()
            },
            mockConfirmUserAttributeOutputResponse: { _ in
                try VerifyUserAttributeOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockChangePasswordOutputResponse: { _ in
                try ChangePasswordOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
    }

    /// Test fetchUserAttributes operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchUserAttributes operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testFetchUserAttributesRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let options = AuthFetchUserAttributesRequest.Options()
        let operation = plugin.fetchUserAttributes(options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test fetchDevices operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testFetchUserAttributesRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.fetchUserAttributes { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(userAttribute:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttribute:) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdateUserAttributeRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let pluginOptions = AWSUpdateUserAttributeOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.update(userAttribute: emailAttribute, options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(userAttribute:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttribute:) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdateUserAttributeRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let operation = plugin.update(userAttribute: emailAttribute) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(userAttributes:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttributes:) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdateUserAttributesRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        let pluginOptions = AWSUpdateUserAttributesOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributesRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.update(userAttributes: [emailAttribute, phoneAttribute], options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(userAttributes:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttributes:) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdateUserAttributesRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        let operation = plugin.update(userAttributes: [emailAttribute, phoneAttribute]) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test resendConfirmationCode(for:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendConfirmationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendConfirmationCodeAttributeRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["key": "value"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resendConfirmationCode(for: .email, options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test resendConfirmationCode(for:)  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendConfirmationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendConfirmationCodeAttributeRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.resendConfirmationCode(for: .email) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test confirm(userAttribute: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirm(userAttribute: )  operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmUserAttributeRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let options = AuthConfirmUserAttributeRequest.Options()
        let operation = plugin.confirm(userAttribute: .email, confirmationCode: "code", options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test confirm(userAttribute: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirm(userAttribute: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmUserAttributeRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.confirm(userAttribute: .email, confirmationCode: "code") { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(oldPassword:to: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(oldPassword:to: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdatePasswordRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let options = AuthChangePasswordRequest.Options()
        let operation = plugin.update(oldPassword: "oldpwd", to: "newpwd", options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test update(oldPassword:to: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(oldPassword:to: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdatePasswordRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.update(oldPassword: "oldpwd", to: "newpwd") { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }
}
