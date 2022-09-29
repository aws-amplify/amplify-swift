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

class DeviceBehaviorForgetDeviceTests: BasePluginTest {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                try ForgetDeviceOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test a successful forgetDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successull response
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a successful result with one device forgot
    ///
    func testSuccessfulForgetCurrentDevice() async throws {
        try await plugin.forgetDevice()
    }

    /// Test a successful forgetDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a successful result with one device forgot
    ///
    func testSuccessfulForgetDevice() async throws {

        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
    }

    // MARK: - Service error for ForgetDevice

    /// Test a forgetCurrentDevice with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for forgetDevice
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testForgetCurrentDeviceWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )

        do {
            try await plugin.forgetDevice()
            XCTFail("Should return an error")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a forgetDevice with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for forgetDevice
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testforgetDeviceWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
            XCTFail("Should return an error")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
    }

    /// Test a forgetDevice call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testforgetCurrentDeviceWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        do {
            try await plugin.forgetDevice()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testforgetDeviceWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with InvalidUserPoolConfigurationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testforgetCurrentDeviceWithInvalidUserPoolConfigurationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
        do {
            try await plugin.forgetDevice()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration error instead of \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with InvalidUserPoolConfigurationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testforgetDeviceWithInvalidUserPoolConfigurationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration error instead of \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testforgetCurrentDeviceWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        do {
            try await plugin.forgetDevice()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testforgetDeviceWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a forgetDevice call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testforgetCurrentDeviceWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
        do {
            try await plugin.forgetDevice()
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

    /// Test a forgetDevice call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testforgetDeviceWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
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

    /// Test a forgetDevice call with ResourceNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testforgetCurrentDeviceWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        do {
            try await plugin.forgetDevice()
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

    /// Test a forgetDevice call with ResourceNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testforgetDeviceWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
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

    /// Test a forgetDevice call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testforgetCurrentDeviceWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        do {
            try await plugin.forgetDevice()
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

    /// Test a forgetDevice call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testforgetDeviceWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
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

    /// Test a forgetDevice call with UserNotConfirmed response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testforgetCurrentDeviceWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        do {
            try await plugin.forgetDevice()
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

    /// Test a forgetDevice call with UserNotConfirmed response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testforgetDeviceWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
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

    /// Test a forgetDevice call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testForgetCurrentDeviceWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        do {
            try await plugin.forgetDevice()
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

    /// Test a forgetDevice call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testForgetDeviceWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        do {
            try await plugin.forgetDevice(awsAuthDevice, options: AuthForgetDeviceRequest.Options())
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
