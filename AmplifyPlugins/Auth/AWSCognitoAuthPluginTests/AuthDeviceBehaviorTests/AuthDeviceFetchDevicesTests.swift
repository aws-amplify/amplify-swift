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
class AuthDeviceFetchDevicesTests: BaseAuthDeviceTest {

    /// Test a successful fetchDevices call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a successful result with one device fetched
    ///
    func testSuccessfulListDevices() {

        let listDevicesMockResult = ListDevicesResult(devices: [Device()],
                                                      paginationToken: nil)
        mockAWSMobileClient?.listDevicesMockResult = .success(listDevicesMockResult)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let listDevicesResult):
                guard listDevicesResult.count == 1 else {
                    XCTFail("Result should have device count of 1")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }

        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a fetchDevices call with invalid response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a invalid response
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testListDevicesWithInvalidResult() {

        mockAWSMobileClient?.listDevicesMockResult = nil
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let listDevicesResult):
                XCTFail("Should not receive a success response \(listDevicesResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should receive unknown error instead got \(error)")
                    return
                }
            }
        }

        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error for listDevices

    /// Test a fetchDevices with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for fetchDevice
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testListDevicesWithInternalErrorException() {

        mockAWSMobileClient.listDevicesMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testListDevicesWithInvalidParameterException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testListDevicesWithInvalidUserPoolConfigurationException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.invalidUserPoolConfiguration(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testListDevicesWithNotAuthorizedException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testListDevicesWithPasswordResetRequiredException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.passwordResetRequired(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with ResourceNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testListDevicesWithResourceNotFoundException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testListDevicesWithTooManyRequestsException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testListDevicesWithUserNotConfirmedException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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

    /// Test a fetchDevices call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testListDevicesWithUserNotFoundException() {

        mockAWSMobileClient?.listDevicesMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchDevices { result in
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
