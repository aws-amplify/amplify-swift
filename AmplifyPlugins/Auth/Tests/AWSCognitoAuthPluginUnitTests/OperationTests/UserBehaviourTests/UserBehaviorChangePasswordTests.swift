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
import AWSCognitoIdentityProvider

class UserBehaviorChangePasswordTests: BasePluginTest {

    /// Test a successful changePassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke changePassword with old password and new password
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulChangePassword() {

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            return try! ChangePasswordOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.internalErrorException(.init(message: "internal error exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.invalidParameterException(.init(message: "invalid parameter exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.invalidPasswordException(.init(message: "invalid password exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.limitExceededException(.init(message: "limit exceeded exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.notAuthorizedException(.init(message: "not authorized exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.passwordResetRequiredException(.init(message: "password reset required exception"))
        })

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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.resourceNotFoundException(.init(message: "resource not found exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.tooManyRequestsException(.init(message: "too many requests exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.userNotConfirmedException(.init(message: "user not confirmed exception"))
        })
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

        self.mockIdentityProvider = MockIdentityProvider(mockChangePasswordOutputResponse: { _ in
            throw ChangePasswordOutputError.userNotFoundException(.init(message: "user not found exception"))
        })
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
