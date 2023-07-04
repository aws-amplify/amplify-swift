//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentityProvider
import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

class DeviceBehaviorRememberDeviceTests: BasePluginTest {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                try UpdateDeviceStatusOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test rememberDevice operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call rememberDevice task
    /// - Then:
    ///    - I should get a successfully executed task
    ///
    func testRememberDeviceRequest() async throws {
        let options = AuthRememberDeviceRequest.Options()
        try await plugin.rememberDevice(options: options)
    }

    /// Test rememberDevice operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call rememberDevice task
    /// - Then:
    ///    - I should get a successfully executed task
    ///
    func testRememberDeviceRequestWithoutOptions() async throws {
        try await plugin.rememberDevice(options: nil)
    }

    /// Test a successful rememberDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a successfully executed task
    ///
    func testSuccessfulRememberDevice() async throws {
        try await plugin.rememberDevice(options: nil)
    }

    // MARK: - Service error for UpdateDeviceStatus
    /// Test a rememberDevice with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for rememberDevice
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testRememberDeviceWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a rememberDevice call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testRememberDeviceWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testRememberDeviceWithInvalidUserPoolConfigurationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw SdkError.service(
                    UpdateDeviceStatusOutputError.invalidUserPoolConfigurationException(
                        .init()),
                    .init(body: .empty, statusCode: .accepted))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration error instead of \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testRememberDeviceWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testRememberDeviceWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with ResourceNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testRememberDeviceWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be resourceNotFound \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testRememberDeviceWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testRememberDeviceWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

    /// Test a rememberDevice call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testRememberDeviceWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        do {
            try await plugin.rememberDevice(options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

}
