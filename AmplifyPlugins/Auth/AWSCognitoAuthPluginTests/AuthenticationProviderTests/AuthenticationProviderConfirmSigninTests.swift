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

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class AuthenticationProviderConfirmSigninTests: BaseAuthenticationProviderTest {

    /// Test a successful confirmSignIn call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulConfirmSignIn() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.confirmSignInMockResult = .success(mockSigninResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignInResult):
                guard case .done = confirmSignInResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a confirmSignIn call with an empty confirmation code
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmSignIn with an empty confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testSuccessfullyConfirmSignIn() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.confirmSignInMockResult = .success(mockSigninResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "") { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    // MARK: Service error handling test

    /// Test a confirmSignIn call with aliasExistsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   aliasExistsException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .aliasExists as underlyingError
    ///
    func testConfirmSignInWithAliasExistsException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.aliasExists(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmSignInWithCodeMismatchException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.codeMismatch(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmSignInWithExpiredCodeException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.expiredCode(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmSignInWithInternalErrorException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithInvalidLambdaResponseException() {
        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmSignInWithInvalidParameterException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with InvalidPasswordException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidPassword as underlyingError
    ///
    func testConfirmSignInWithInvalidPasswordException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.invalidPassword(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a --
    ///
    func testConfirmSignInWithinvalidSmsRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a confirmSignIn call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a --
    ///
    func testConfirmSignInWithInvalidSmsRoleTrustRelationshipException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a confirmSignIn with InvalidSmsRoleTrustRelationshipException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleTrustRelationshipException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testConfirmSignInWithInvalidUserPoolConfigurationException() {
        mockAWSMobileClient.confirmSignInMockResult =
            .failure(AWSMobileClientError.invalidUserPoolConfiguration(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn with MFAMethodNotFoundException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   MFAMethodNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .mfaMethodNotFound as underlyingError
    ///
    func testCofirmSignInWithMFAMethodNotFoundException() {

        mockAWSMobileClient.confirmSignInMockResult = .failure(AWSMobileClientError.mfaMethodNotFound(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .mfaMethodNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be mfaMethodNotFound \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmSignInWithNotAuthorizedException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn with PasswordResetRequiredException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testConfirmSignInWithPasswordResetRequiredException() {

        mockAWSMobileClient.confirmSignInMockResult =
            .failure(AWSMobileClientError.passwordResetRequired(message: "Error"))

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignInResult):
                guard case .resetPassword = confirmSignInResult.nextStep else {
                    XCTFail("Result should be .resetPassword for next step")
                    return
                }
            case .failure(let error):
                XCTFail("Should not return error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testConfirmSignInWithResourceNotFoundException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with SoftwareTokenMFANotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .softwareTokenMFANotEnabled as underlyingError
    ///
    func testConfirmSignInWithSoftwareTokenMFANotFoundException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.softwareTokenMFANotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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
                guard case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be softwareTokenMFANotEnabled \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmSignInWithTooManyRequestsException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithUnexpectedLambdaException() {

        mockAWSMobileClient?.confirmSignInMockResult = .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithUserLambdaValidationException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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

    /// Test a confirmSignIn call with UserNotConfirmedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get .confirmSignUp as next step
    ///
    func testConfirmSignInWithUserNotConfirmedException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignInResult):
                guard case .confirmSignUp = confirmSignInResult.nextStep else {
                    XCTFail("Result should be .confirmSignUp for next step")
                    return
                }
            case .failure(let error):
                XCTFail("Should not return error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmSignInWithUserNotFoundException() {

        mockAWSMobileClient?.confirmSignInMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
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
