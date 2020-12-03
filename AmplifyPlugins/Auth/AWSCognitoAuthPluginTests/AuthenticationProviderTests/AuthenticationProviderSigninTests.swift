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
class AuthenticationProviderSigninTests: BaseAuthenticationProviderTest {

    /// Test a signIn with valid inputs
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testSuccessfulSignIn() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)

        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with empty username
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with empty username
    /// - Then:
    ///    - I should get a .validation error
    ///
    func testSignInWithEmptyUsername() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)
        let options = AuthSignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not receive a success response \(signinResult)")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should receive validation error instead got \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with empty password
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with no password
    /// - Then:
    ///    - I should get a valid response
    ///
    func testSignInWithEmptyPassword() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)
        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with nil as reponse from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mock nil response from service
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInvalidResult() {

        mockAWSMobileClient?.signInMockResult = nil
        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not receive a success response \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should receive unknown error instead got \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with smsMFA as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock smsMFA response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithSMSMFACode
    ///
    func testSignInWithNextStepSMS() {

        let mockSigninResult = SignInResult(signInState: .smsMFA)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithSMSMFACode = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithSMSMFACode for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with customChallenge as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock customChallenge response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithCustomChallenge
    ///
    func testSignInWithNextStepCustomChallenge() {

        let mockSigninResult = SignInResult(signInState: .customChallenge)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithCustomChallenge = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithCustomChallenge for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with newPassword as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock newPassword response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithNewPassword error
    ///
    func testSignInWithNextStepNewPassword() {

        let mockSigninResult = SignInResult(signInState: .newPasswordRequired)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithNewPassword = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithNewPassword for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with invalid response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock unknown response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithNextStepUnknown() {

        let mockSigninResult = SignInResult(signInState: .unknown)
        mockAWSMobileClient?.signInMockResult = .success(mockSigninResult)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):

                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error for initiateAuth

    /// Test a signIn with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInternalErrorException() {
        let error = AWSMobileClientError.internalError(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidLambdaResponseException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithInvalidLambdaResponseException() {
        let error = AWSMobileClientError.invalidLambdaResponse(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testSignInWithInvalidParameterException() {
        let error = AWSMobileClientError.invalidParameter(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce invalidParameter error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidUserPoolConfigurationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testSignInWithInvalidUserPoolConfigurationException() {
        let error = AWSMobileClientError.invalidUserPoolConfiguration(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .configuration = error else {
                    XCTFail("Should produce configuration intead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSignInWithNotAuthorizedException() {
        let error = AWSMobileClientError.notAuthorized(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `PasswordResetRequiredException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testSignInWithPasswordResetRequiredException() {
        let error = AWSMobileClientError.passwordResetRequired(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .resetPassword = signinResult.nextStep else {
                    XCTFail("Result should be .resetPassword for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Should not produce error - \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testSignInWithResourceNotFoundException() {
        let error = AWSMobileClientError.resourceNotFound(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testSignInWithTooManyRequestsException() {
        let error = AWSMobileClientError.tooManyRequests(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce requestLimitExceeded error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UnexpectedLambdaException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUnexpectedLambdaException() {
        let error = AWSMobileClientError.unexpectedLambda(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserLambdaValidationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUserLambdaValidationException() {
        let error = AWSMobileClientError.userLambdaValidation(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserNotConfirmedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignUp as next step
    ///
    func testSignInWithUserNotConfirmedException() {
        let error = AWSMobileClientError.userNotConfirmed(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignUp = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignUp for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Should not produce error - \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .userNotFound error
    ///
    func testSignInWithUserNotFoundException() {
        let error = AWSMobileClientError.userNotFound(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userNotFound error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error for RespondToAuthChallenge

    /// Test a signIn with `AliasExistsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   AliasExistsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .aliasExists error
    ///
    func testSignInWithAliasExistsException() {
        let error = AWSMobileClientError.aliasExists(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce aliasExists error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidPasswordException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .invalidPassword error
    ///
    func testSignInWithInvalidPasswordException() {
        let error = AWSMobileClientError.invalidPassword(message: "Error")
        mockAWSMobileClient.signInMockResult = .failure(error)

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidPassword = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce invalidPassword error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
