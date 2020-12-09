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

class AuthDeviceRememberDeviceTests: BaseAuthDeviceTest {

    /// Test a successful rememberDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a successful result indicating device status updated
    ///
    func testSuccessfulRememberDevice() {

        let rememberDeviceMockResult = UpdateDeviceStatusResult()
        mockAWSMobileClient?.rememberDeviceMockResult = .success(rememberDeviceMockResult)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }

        wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testRememberDeviceWithInternalErrorException() {

        mockAWSMobileClient.rememberDeviceMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let listDevicesResult):
                XCTFail("Should not produce result - \(listDevicesResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testRememberDeviceWithInvalidParameterException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
                guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalidParameter \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testRememberDeviceWithInvalidUserPoolConfigurationException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.invalidUserPoolConfiguration(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithNotAuthorizedException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithPasswordResetRequiredException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.passwordResetRequired(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithResourceNotFoundException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithTooManyRequestsException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithUserNotConfirmedException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.rememberDevice { result in
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
    func testRememberDeviceWithUserNotFoundException() {

        mockAWSMobileClient?.rememberDeviceMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.rememberDevice { result in
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
