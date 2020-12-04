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
class AuthenticationProviderConfirmSignupTests: BaseAuthenticationProviderTest {

    /// Test a successful confirmSignup call with .done as next step
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignup with username and confirmationCode
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulConfirmSignUp() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmSignUpMockResult = .success(mockSignupResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignupResult):
                guard case .done = confirmSignupResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(confirmSignupResult.isSignupComplete, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignup call with an empty username
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmSignup with an empty username and confirmationCode
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmSignUpWithEmptyUserName() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmSignUpMockResult = .success(mockSignupResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with invalid response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a invalid response
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testSignupWithInvalidResult() {

        mockAWSMobileClient?.confirmSignUpMockResult = nil
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should return an error if the result from service is invalid")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce an unknown error")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: Service error handling test

    /// Test a confirmSignup call with aliasExistsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   aliasExistsException response
    /// - When:
    ///    - I invoke confirmSignuUp with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .aliasExists as underlyingError
    ///
    func testConfirmSignUpWithAliasExistsException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.aliasExists(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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
                guard case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be aliasExists \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignup call with CodeMismatchException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke confirmSignuUp with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmSignUpWithCodeMismatchException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.codeMismatch(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with CodeExpiredException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke confirmSignuUp with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmSignUpWithExpiredCodeException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.expiredCode(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with InternalErrorException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmSignUpWithInternalErrorException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with InvalidLambdaResponseException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignUpWithInvalidLambdaResponseException() {
        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with InvalidParameterException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmSignUpWithInvalidParameterException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with LimitExceededException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .requestLimitExceeded error
    ///
    func testConfirmSignUpWithLimitExceededException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.limitExceeded(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with NotAuthorizedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmSignUpWithNotAuthorizedException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with ResourceNotFoundException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testConfirmSignUpWithResourceNotFoundException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with TooManyFailedAttempts response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .failedAttemptsLimitExceeded as underlyingError
    ///
    func testConfirmSignUpWithTooManyFailedAttemptsException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.tooManyFailedAttempts(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with TooManyRequestsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmSignUpWithTooManyRequestsException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with UnexpectedLambdaException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignUpWithUnexpectedLambdaException() {

        mockAWSMobileClient?.confirmSignUpMockResult = .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with UserLambdaValidationException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignUpWithUserLambdaValidationException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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

    /// Test a confirmSignup call with UserNotFound response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignup with a valid username and confirmationCode
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmSignUpWithUserNotFoundException() {

        mockAWSMobileClient?.confirmSignUpMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
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
