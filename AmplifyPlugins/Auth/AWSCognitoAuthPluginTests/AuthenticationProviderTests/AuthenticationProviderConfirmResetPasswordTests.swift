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
// swiftlint:disable:next type_name
class AuthenticationProviderConfirmResetPasswordTests: BaseAuthenticationProviderTest {

    /// Test a successful confirmResetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignup with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulConfirmResetPassword() {
        let confirmResetPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .done,
                                                                  codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmForgotPasswordMockResult = .success(confirmResetPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        let confirmResetPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .done,
                                                                  codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .success(confirmResetPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        let confirmResetPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .done,
                                                                  codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .success(confirmResetPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.codeMismatch(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.expiredCode(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.invalidPassword(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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

    /// Test a confirmResetPassword call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .requestLimitExceeded error
    ///
    func testConfirmResetPasswordWithLimitExceededException() {

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.limitExceeded(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
                    XCTFail("Underlying error should be resourceNotFound \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.tooManyFailedAttempts(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
        wait(for: [resultExpectation], timeout: apiTimeout)
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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

        mockAWSMobileClient?.confirmForgotPasswordMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmResetPassword(for: "username",
                                        with: "newpassword",
                                        confirmationCode: "code") { result in
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
