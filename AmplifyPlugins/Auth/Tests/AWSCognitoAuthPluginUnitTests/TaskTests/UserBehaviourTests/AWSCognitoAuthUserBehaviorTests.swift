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
                try await VerifyUserAttributeOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockChangePasswordOutputResponse: { _ in
                try await ChangePasswordOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
    }

    /// Test fetchUserAttributes operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchUserAttributes operation
    /// - Then:
    ///    - I should get a valid task execution
    ///
    func testFetchUserAttributesRequest() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            GetUserOutputResponse(
                mfaOptions: [],
                preferredMfaSetting: "",
                userAttributes: [.init(name: "email", value: "Amplify@amazon.com")],
                userMFASettingList: [],
                username: ""
            )
        })
        let options = AuthFetchUserAttributesRequest.Options()
        _ = try await plugin.fetchUserAttributes(options: options)
    }

    /// Test fetchDevices operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a valid task execution
    ///
    func testFetchUserAttributesRequestWithoutOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            GetUserOutputResponse(
                mfaOptions: [],
                preferredMfaSetting: "",
                userAttributes: [.init(name: "email", value: "Amplify@amazon.com")],
                userMFASettingList: [],
                username: ""
            )
        })
        _ = try await plugin.fetchUserAttributes()
    }

    /// Test update(userAttribute:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttribute:) operation
    /// - Then:
    ///    - I should get a valid task execution
    ///
    func testUpdateUserAttributeRequest() async throws {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let pluginOptions = AWSAuthUpdateUserAttributeOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.update(userAttribute: emailAttribute, options: options)
    }

    /// Test update(userAttribute:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttribute:) operation
    /// - Then:
    ///    - I should get a valid task execution
    ///
    func testUpdateUserAttributeRequestWithoutOptions() async throws {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        _ = try await plugin.update(userAttribute: emailAttribute)
    }

    /// Test update(userAttributes:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttributes:) operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testUpdateUserAttributesRequest() async throws {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        let pluginOptions = AWSAuthUpdateUserAttributesOptions(metadata: ["key": "value"])
        let options = AuthUpdateUserAttributesRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.update(userAttributes: [emailAttribute, phoneAttribute], options: options)
    }

    /// Test update(userAttributes:) operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(userAttributes:) operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testUpdateUserAttributesRequestWithoutOptions() async throws {
        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let phoneAttribute = AuthUserAttribute(.phoneNumber, value: "123213")
        _ = try await plugin.update(userAttributes: [emailAttribute, phoneAttribute])
    }

    /// Test resendConfirmationCode(for:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendConfirmationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testResendConfirmationCodeAttributeRequest() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            GetUserAttributeVerificationCodeOutputResponse(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["key": "value"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test resendConfirmationCode(for:) operation can be invoked with plugin options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendConfirmationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testResendConfirmationCodeWithPluginOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { request in

            XCTAssertNotNil(request.clientMetadata)
            XCTAssertEqual(request.clientMetadata?["key"], "value")
            return GetUserAttributeVerificationCodeOutputResponse(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        let pluginOptions = AWSAttributeResendConfirmationCodeOptions(metadata: ["key": "value"])
        let options = AuthAttributeResendConfirmationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test resendConfirmationCode(for:)  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendConfirmationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testResendConfirmationCodeAttributeRequestWithoutOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            GetUserAttributeVerificationCodeOutputResponse(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
    }

    /// Test confirm(userAttribute: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirm(userAttribute: )  operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmUserAttributeRequest() async throws {
        let options = AuthConfirmUserAttributeRequest.Options()
        try await plugin.confirm(userAttribute: .email, confirmationCode: "code", options: options)
    }

    /// Test confirm(userAttribute: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirm(userAttribute: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmUserAttributeRequestWithoutOptions() async throws {
        try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
    }

    /// Test update(oldPassword:to: ) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(oldPassword:to: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdatePasswordRequest() async throws {
        let options = AuthChangePasswordRequest.Options()
        try await plugin.update(oldPassword: "oldpwd", to: "newpwd", options: options)
    }

    /// Test update(oldPassword:to: )  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call update(oldPassword:to: ) operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testUpdatePasswordRequestWithoutOptions() async throws {
        try await plugin.update(oldPassword: "oldpwd", to: "newpwd")
    }
}
