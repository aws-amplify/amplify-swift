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
class AuthenticationProviderResetPasswordTests: BaseAuthenticationProviderTest {

    /// Test a successful resetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulResetPassword() {
        let codeDeliveryDetails = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                          destination: "Amplify@amazon.com",
                                                          attributeName: "attribute")
        let forgotPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .confirmationCodeSent,
                                                            codeDeliveryDetails: codeDeliveryDetails)
        mockAWSMobileClient?.forgotPasswordMockResult = .success(forgotPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a resetPassword call with nil UserCodeDeliveryDetails
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResetPasswordWithNilCodeDeliveryDetails() {

        let resetPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .done,
                                                           codeDeliveryDetails: nil)
        mockAWSMobileClient?.forgotPasswordMockResult =
            .success(resetPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a resetPassword call with empty username
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with empty username
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testResetPasswordWithEmptyUsername() {

        let codeDeliveryDetails = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                          destination: "Amplify@amazon.com",
                                                          attributeName: "attribute")
        let resetPasswordMockResult = ForgotPasswordResult(forgotPasswordState: .done,
                                                           codeDeliveryDetails: codeDeliveryDetails)
        mockAWSMobileClient?.forgotPasswordMockResult =
            .success(resetPasswordMockResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "") { result in
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

    /// Test a resetPassword call with CodeDeliveryFailureException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .codeDelivery as underlyingError
    ///
    func testResetPasswordWithCodeDeliveryFailureException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.codeDeliveryFailure(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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
                    XCTFail("Underlying error should be codeDelivery \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a resetPassword call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResetPasswordWithInternalErrorException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with InvalidEmailRoleAccessPolicyException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidEmailRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a --
    ///
    func testResetPasswordWithInvalidEmailRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resetPassword call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResetPasswordWithInvalidLambdaResponseException() {
        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testResetPasswordWithInvalidParameterException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a --
    ///
    func testResetPasswordWithInvalidSmsRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resetPassword call with InvalidSmsRoleTrustRelationshipException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a --
    ///
    func testResetPasswordWithInvalidSmsRoleTrustRelationshipException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a resetPassword call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testResetPasswordWithLimitExceededException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.limitExceeded(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testResetPasswordWithNotAuthorizedException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testResetPasswordWithResourceNotFoundException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testResetPasswordWithTooManyRequestsException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResetPasswordWithUnexpectedLambdaException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testResetPasswordWithUserLambdaValidationException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testResetPasswordWithUserNotConfirmedException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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

    /// Test a resetPassword call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testResetPasswordWithUserNotFoundException() {

        mockAWSMobileClient?.forgotPasswordMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user") { result in
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
