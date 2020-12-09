//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class AuthDeviceForgetDeviceTests: BaseAuthDeviceTest {

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

        wait(for: [resultExpectation], timeout: apiTimeout)
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

        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient.forgetCurrentDeviceMockResult =
            AWSMobileClientError.internalError(message: "Error")

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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient.forgetDeviceMockResult =
            AWSMobileClientError.internalError(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.invalidParameter(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.invalidParameter(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a forgetDevice call with InvalidParameterException response from service
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.invalidUserPoolConfiguration(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a forgetDevice call with InvalidParameterException response from service
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.invalidUserPoolConfiguration(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.notAuthorized(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.notAuthorized(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.passwordResetRequired(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.passwordResetRequired(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.resourceNotFound(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.resourceNotFound(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.tooManyRequests(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.tooManyRequests(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a forgetDevice call with UserNotFound response from service
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.userNotConfirmed(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a forgetDevice call with UserNotFound response from service
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.userNotConfirmed(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetCurrentDeviceMockResult =
            AWSMobileClientError.userNotFound(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.forgetDeviceMockResult =
            AWSMobileClientError.userNotFound(message: "Error")
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
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
