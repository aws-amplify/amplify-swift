//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon

class ClientBehaviorConfirmResetPasswordTests: AWSCognitoAuthClientBehaviorTests {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test confirmResetPassword operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let pluginOptions = ["key": "value"]
        let options = AuthConfirmResetPasswordRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.confirmResetPassword(for: "username",
                                                    with: "password",
                                                    confirmationCode: "code",
                                                    options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test confirmResetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.confirmResetPassword(for: "username",
                                                    with: "password",
                                                    confirmationCode: "code",
                                                    options: nil) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test a successful confirmResetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignup with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulConfirmResetPassword() {
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with empty username
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmResetPassword with an empty username, a new password and a confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmResetPasswordWithEmptyUserName() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should produce validation error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with empty new password
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, an empty new password and a confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmResetPasswordWithEmptyNewPassword() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "",
                                           confirmationCode: "code",
                                           options: nil) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should produce validation error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmResetPasswordWithCodeMismatchException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.codeMismatchException(CodeMismatchException(message: "code mismatch"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be codeMismatch \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmResetPasswordWithExpiredCodeException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.expiredCodeException(ExpiredCodeException(message: "code expired"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .codeExpired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be codeExpired \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmResetPasswordWithInternalErrorException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidLambdaResponseException() {
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.invalidLambdaResponseException(InvalidLambdaResponseException(message: "invalid lambda"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be lambda \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidParameterException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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

    /// Test a confirmResetPassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .invalidPassword as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidPasswordException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.invalidPasswordException(InvalidPasswordException(message: "invalid password"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testConfirmResetPasswordWithLimitExceededException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.limitExceededException(LimitExceededException(message: "limit exceeded"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmResetPasswordWithNotAuthorizedException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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

    /// Test a confirmResetPassword call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .resourceNotFound error
    ///
    func testConfirmResetPasswordWithResourceNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                    XCTFail("Underlying error should be failedAttemptsLimitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with TooManyFailedAttempts response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyFailedAttemptsException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .failedAttemptsLimitExceeded as underlyingError
    ///
    func testConfirmResetPasswordWithTooManyFailedAttemptsException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.tooManyFailedAttemptsException(TooManyFailedAttemptsException(message: "too many failed attempts"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .failedAttemptsLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be failedAttemptsLimitExceeded \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmResetPasswordWithTooManyRequestsException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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

    /// Test a confirmResetPassword call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithUnexpectedLambdaException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.unexpectedLambdaException(UnexpectedLambdaException(message: "unexpected lambda"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be lambda \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithUserLambdaValidationException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.userLambdaValidationException(UserLambdaValidationException(message: "user lambda invalid"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be lambda \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a confirmResetPassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .userNotConfirmed error
    ///
    func testConfirmResetPasswordWithUserNotConfirmedException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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

    /// Test a confirmResetPassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmResetPasswordWithUserNotFoundException() {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw ConfirmForgotPasswordOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                           with: "newpassword",
                                           confirmationCode: "code",
                                           options: nil) { result in
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
