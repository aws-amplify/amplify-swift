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
@testable import AWSMobileClient

class UserBehaviorChangePasswordTests: BaseUserBehaviorTest {

    /// Test a successful changePassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulChangePassword() {

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a changePassword call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testChangePasswordWithInternalErrorException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.internalError(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce an unknown error instead of \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a changePassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testChangePasswordWithInvalidParameterException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.invalidParameter(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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

    /// Test a changePassword call with InvalidPasswordException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with  .invalidPassword as underlyingError
    ///
    func testChangePasswordWithInvalidPasswordException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.invalidPassword(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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
                guard case .invalidPassword = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalidPassword \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a changePassword call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testChangePasswordWithLimitExceededException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.limitExceeded(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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
                guard case .limitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be limitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a changePassword call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testChangePasswordWithNotAuthorizedException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.notAuthorized(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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

    /// Test a changePassword with PasswordResetRequiredException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError as underlying error
    ///
    func testChangePasswordWithPasswordResetRequiredException() {

        mockAWSMobileClient.changePasswordMockResult =
            AWSMobileClientError.passwordResetRequired(message: "Error")

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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

    /// Test a changePassword call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testChangePasswordWithResourceNotFoundException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.resourceNotFound(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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

    /// Test a changePassword call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testChangePasswordWithTooManyRequestsException() {

        mockAWSMobileClient?.changePasswordMockResult = AWSMobileClientError.tooManyRequests(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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

    /// Test a changePassword call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed error as underlyingError
    ///
    func testChangePasswordWithUserNotConfirmedException() {

        mockAWSMobileClient?.changePasswordMockResult =
            AWSMobileClientError.userNotConfirmed(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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
                    XCTFail("Underlying error should be userNotConfirmed \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a changePassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testChangePasswordWithUserNotFoundException() {

        mockAWSMobileClient?.changePasswordMockResult =
            AWSMobileClientError.userNotFound(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(oldPassword: "old password", to: "new password") { result in
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
