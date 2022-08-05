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

class DeviceBehaviorFetchDevicesTests: AWSAuthDeviceBehaviorTests {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                try ListDevicesOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test fetchDevices operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call fetchDevices operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testFetchDevicesRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let options = AuthFetchDevicesRequest.Options()
        let operation = plugin.fetchDevices(options: options) { _ in
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
    func testFetchDevicesRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.fetchDevices { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test a successful fetchDevices call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - I should get a successful result with one device fetched
    ///
    func testSuccessfulListDevices() {

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: [CognitoIdentityProviderClientTypes.DeviceType(deviceKey: "id")], paginationToken: nil)
            }
        )
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

        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                ListDevicesOutputResponse(devices: nil, paginationToken: nil)
            }
        )
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

        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockListDevicesOutputResponse: { _ in
                throw ListDevicesOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
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
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

}
