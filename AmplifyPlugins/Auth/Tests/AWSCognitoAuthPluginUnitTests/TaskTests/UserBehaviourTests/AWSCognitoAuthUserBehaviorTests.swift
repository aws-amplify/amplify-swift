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
            mockGetUserAttributeVerificationCodeOutput: { _ in
                GetUserAttributeVerificationCodeOutput()
            },
            mockGetUserAttributeResponse: { _ in
                GetUserOutput()
            },
            mockUpdateUserAttributeResponse: { _ in
                UpdateUserAttributesOutput()
            },
            mockConfirmUserAttributeOutput: { _ in
                VerifyUserAttributeOutput()
            },
            mockChangePasswordOutput: { _ in
                ChangePasswordOutput()
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
            GetUserOutput(
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
            GetUserOutput(
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

    /// Test sendVerificationCode(for:) operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call sendVerificationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testSendVerificationCodeAttributeRequest() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        let pluginOptions = AWSSendUserAttributeVerificationCodeOptions(metadata: ["key": "value"])
        let options = AuthSendUserAttributeVerificationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test sendVerificationCode(for:) operation can be invoked with plugin options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call sendVerificationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testSendVerificationCodeWithPluginOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { request in

            XCTAssertNotNil(request.clientMetadata)
            XCTAssertEqual(request.clientMetadata?["key"], "value")
            return GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        let pluginOptions = AWSSendUserAttributeVerificationCodeOptions(metadata: ["key": "value"])
        let options = AuthSendUserAttributeVerificationCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email, options: options)
    }

    /// Test sendVerificationCode(for:)  operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call sendVerificationCode(for:)  operation
    /// - Then:
    ///    - I should get a valid task completion
    ///
    func testSendVerificationCodeAttributeRequestWithoutOptions() async throws {
        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })
        _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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
