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
    ///    - I call rememberDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testRememberDeviceRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let options = AuthRememberDeviceRequest.Options()
        let operation = plugin.rememberDevice(options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: apiTimeout)
    }

    /// Test rememberDevice operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call rememberDevice operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testRememberDeviceRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.rememberDevice { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: apiTimeout)
    }

    /// Test a successful rememberDevice call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke rememberDevice
    /// - Then:
    ///    - I should get a successful result indicating device status updated
    ///
    func testSuccessfulRememberDevice() {
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )

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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException(message: "invalid user pool configuration"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.passwordResetRequiredException(PasswordResetRequiredException(message: "password reset required"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
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

        mockIdentityProvider = MockIdentityProvider(
            mockRememberDeviceResponse: { _ in
                throw UpdateDeviceStatusOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
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
