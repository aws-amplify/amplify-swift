//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest

import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon


class DeviceBehaviorForgetDeviceTests: BasePluginTest {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                ForgetDeviceOutputResponse()
            }
        )
    }

    /// Test a successful forgetDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
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
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
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
                throw InternalErrorException(name: nil, message: "internal error", httpURLResponse: .init())
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
                throw InternalErrorException(name: nil, message: "internal error", httpURLResponse: .init())
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
                throw try await InvalidParameterException(
                    name: nil,
                    message: nil,
                    httpURLResponse: .init()
                )
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
                throw InvalidParameterException(name: nil, message: "invalid parameter", httpURLResponse: .init())
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
                throw InvalidUserPoolConfigurationException(name: nil, message: "invalid user pool configuration", httpURLResponse: .init())
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
                throw InvalidUserPoolConfigurationException(name: nil, message: "invalid user pool configuration", httpURLResponse: .init())
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
                throw NotAuthorizedException(name: nil, message: "not authorized", httpURLResponse: .init())
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
                throw NotAuthorizedException(name: nil, message: "not authorized", httpURLResponse: .init())
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
                throw PasswordResetRequiredException(name: nil, message: "password reset required", httpURLResponse: .init())
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
                throw PasswordResetRequiredException(name: nil, message: "password reset required", httpURLResponse: .init())
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
                throw ResourceNotFoundException(name: nil, message: "resource not found", httpURLResponse: .init())
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
                throw ResourceNotFoundException(name: nil, message: "resource not found", httpURLResponse: .init())
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
                throw TooManyRequestsException(name: nil, message: "too many requests", httpURLResponse: .init())
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
                throw TooManyRequestsException(name: nil, message: "too many requests", httpURLResponse: .init())
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
                throw UserNotConfirmedException(name: nil, message: "user not confirmed", httpURLResponse: .init())
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
                throw UserNotConfirmedException(name: nil, message: "user not confirmed", httpURLResponse: .init())
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
                throw UserNotFoundException(name: nil, message: "user not found", httpURLResponse: .init())
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
                throw UserNotFoundException(name: nil, message: "user not found", httpURLResponse: .init())
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
