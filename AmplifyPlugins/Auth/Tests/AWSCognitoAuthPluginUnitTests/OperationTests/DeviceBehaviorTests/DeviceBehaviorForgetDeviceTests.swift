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

class DeviceBehaviorForgetDeviceTests: AWSAuthDeviceBehaviorTests {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                try ForgetDeviceOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test forgetDevice operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call forgetDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testForgetDeviceRequest() {
        let options = AuthForgetDeviceRequest.Options()
        let operation = plugin.forgetDevice(options: options)
        XCTAssertNotNil(operation)
    }

    /// Test forgetDevice operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call forgetDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testForgetDeviceRequestWithoutOptions() {
        let operation = plugin.forgetDevice()
        XCTAssertNotNil(operation)
    }

    /// Test a successful forgetDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke forgetDevice
    /// - Then:
    ///    - I should get a successful result with one device forgot
    ///
    func testSuccessfulForgetCurrentDevice() {

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }

        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a successful forgetDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke forgetDevice with an AWSAuthDevice
    /// - Then:
    ///    - I should get a successful result with one device forgot
    ///
    func testSuccessfulForgetDevice() {

        let awsAuthDevice = AWSAuthDevice(id: "authDeviceID",
                                          name: "name",
                                          attributes: nil,
                                          createdDate: nil,
                                          lastAuthenticatedDate: nil,
                                          lastModifiedDate: nil)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }

        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testForgetCurrentDeviceWithInternalErrorException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let forgetDeviceResult):
                XCTFail("Should not produce result - \(forgetDeviceResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithInternalErrorException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let forgetDeviceResult):
                XCTFail("Should not produce result - \(forgetDeviceResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithInvalidParameterException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalidParameter \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithInvalidParameterException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalidParameter \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithInvalidUserPoolConfigurationException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .configuration = error else {
                    XCTFail("Should produce configuration error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithInvalidUserPoolConfigurationException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .configuration = error else {
                    XCTFail("Should produce configuration error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithNotAuthorizedException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithNotAuthorizedException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithPasswordResetRequiredException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be passwordResetRequired \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithPasswordResetRequiredException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be passwordResetRequired \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithResourceNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be resourceNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithResourceNotFoundException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be resourceNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithTooManyRequestsException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be requestLimitExceeded \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithTooManyRequestsException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be requestLimitExceeded \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetCurrentDeviceWithUserNotConfirmedException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testforgetDeviceWithUserNotConfirmedException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testForgetCurrentDeviceWithUserNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(
            mockForgetDeviceResponse: { _ in
                throw ForgetDeviceOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
    func testForgetDeviceWithUserNotFoundException() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.forgetDevice(awsAuthDevice,
                                options: AuthForgetDeviceRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be userNotFound \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }
}
