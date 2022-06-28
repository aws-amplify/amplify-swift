//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

class ClientBehaviorResetPasswordTests : AWSCognitoAuthClientBehaviorTests {
    
    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: .init())
            }
        )
    }
    
    /// Test resetPassword operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResetPasswordRequest() {
        let operationFinished = expectation(description: "Operation should finish")
        let pluginOptions = ["key": "value"]
        let options = AuthResetPasswordRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resetPassword(for: "username", options: options) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }

    /// Test resetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResetPasswordRequestWithoutOptions() {
        let operationFinished = expectation(description: "Operation should finish")
        let operation = plugin.resetPassword(for: "username", options: nil) { _ in
            operationFinished.fulfill()
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 1)
    }
    
    /// Test a successful resetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulResetPassword() {
        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: "attribute",
                                                                                             deliveryMedium: .email,
                                                                                             destination: "Amplify@amazon.com")
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: nil)
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: "attribute",
                                                                                             deliveryMedium: .email,
                                                                                             destination: "Amplify@amazon.com")
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )
        
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.codeDeliveryFailureException(CodeDeliveryFailureException(message: "Code delivery failure"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

    /// Test a resetPassword call with InvalidEmailRoleAccessPolicyException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidEmailRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .emailRole error
    ///
    func testResetPasswordWithInvalidEmailRoleAccessPolicyException() {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.invalidEmailRoleAccessPolicyException(InvalidEmailRoleAccessPolicyException(message: "invalid email role"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
                guard case .emailRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be limitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.invalidLambdaResponseException(InvalidLambdaResponseException(message: "Invalid lambda response"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

    /// Test a resetPassword call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .smsRole error
    ///
    func testResetPasswordWithInvalidSmsRoleAccessPolicyException() {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.invalidSmsRoleAccessPolicyException(InvalidSmsRoleAccessPolicyException(message: "invalid sms role"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
                guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be limitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a resetPassword call with InvalidSmsRoleTrustRelationshipException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .smsRole error
    ///
    func testResetPasswordWithInvalidSmsRoleTrustRelationshipException() {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.invalidSmsRoleTrustRelationshipException(InvalidSmsRoleTrustRelationshipException(message: "invalid sms role trust relationship"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
                guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be limitExceeded \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.limitExceededException(LimitExceededException(message: "limit exceeded"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.unexpectedLambdaException(UnexpectedLambdaException(message: "unexpected lambda"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.userLambdaValidationException(UserLambdaValidationException(message: "user lambda validation exception"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.userNotConfirmedException(UserNotConfirmedException(message: "user not confirmed"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw ForgotPasswordOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resetPassword(for: "user", options: nil) { result in
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
