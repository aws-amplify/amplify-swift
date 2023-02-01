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

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable:next type_name
class AuthenticationProviderResendSignupCodeTests: BaseAuthenticationProviderTest {

    /// Test a successful resendSignUpCode call with .email as the destination of AuthCodeDeliveryDetails
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a successful result with .email as the destination of AuthCodeDeliveryDetails
    ///
    func testResendSignupCodeWithSuccess() {

        let codeDelieveryDetails = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                           destination: nil,
                                                           attributeName: nil)
        let mockResendSignUpCodeResult = SignUpResult(signUpState: .confirmed,
                                                      codeDeliveryDetails: codeDelieveryDetails)
        mockAWSMobileClient?.resendSignUpCodeMockResult = .success(mockResendSignUpCodeResult)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let authCodeDeliveryDetails):
                guard case .email = authCodeDeliveryDetails.destination else {
                    XCTFail("Result should be .email for the destination of AuthCodeDeliveryDetails")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a resendSignUpCode call with empty username
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a failure with validation error
    ///
    func testResendSignupCodeWithEmptyUsername() {

        let codeDelieveryDetails = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                           destination: nil,
                                                           attributeName: nil)
        let mockResendSignUpCodeResult = SignUpResult(signUpState: .confirmed,
                                                      codeDeliveryDetails: codeDelieveryDetails)
        mockAWSMobileClient?.resendSignUpCodeMockResult = .success(mockResendSignUpCodeResult)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "") { result in
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

    /// Test a resendSignUpCode call with invalid response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a invalid response
    /// - When:
    ///    - I invoke resendSignUpCode with valid username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendSignupCodeWithInvalidResult() {

        mockAWSMobileClient?.resendSignUpCodeMockResult = nil
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not succeed")
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

    /// Test a resendSignUpCode call with CodeDeliveryFailureException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .codeDelivery as underlyingError
    ///
    func testResendSignupCodeWithCodeDeliveryFailureException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.codeDeliveryFailure(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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
                guard case .codeDelivery = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be codedelivery \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a resendSignUpCode call with InternalErrorException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendSignupCodeWithInternalErrorException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult = .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with InvalidEmailRoleAccessPolicy response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a --
    ///
    func testResendSignupCodeWithInvalidEmailRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resendSignUpCode call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a --
    ///
    func testResendSignupCodeWithinvalidSmsRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resendSignUpCode call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a --
    ///
    func testResendSignupCodeWithInvalidSmsRoleTrustRelationshipException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resendSignUpCode call with InvalidLambdaResponseException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResendSignupCodeWithInvalidLambdaResponseException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with InvalidParameterException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testResendSignupCodeWithInvalidParameterException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with LimitExceededException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testResendSignupCodeWithLimitExceededException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.limitExceeded(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with NotAuthorizedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testResendSignupCodeWithNotAuthorizedException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with ResourceNotFoundException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testResendSignupCodeWithResourceNotFoundException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with TooManyRequestsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testResendSignupCodeWithTooManyRequestsException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with UnexpectedLambdaException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResendSignupCodeWithUnexpectedLambdaException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with UserLambdaValidationException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResendSignupCodeWithUserLambdaValidationException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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

    /// Test a resendSignUpCode call with UserNotFound response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testResendSignupCodeUpWithUserNotFoundException() {

        mockAWSMobileClient?.resendSignUpCodeMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username") { result in
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
