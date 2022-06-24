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

class ClientBehaviorResendSignUpCodeTests : AWSCognitoAuthClientBehaviorTests {
    
    /// Test resendSignUpCode operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequest() {
        let pluginOptions = ["somekey": "somevalue"]
        let options = AuthResendSignUpCodeRequest.Options(pluginOptions: pluginOptions)
        let operation = plugin.resendSignUpCode(for: "username", options: options)
        XCTAssertNotNil(operation)
    }
    
    /// Test resendSignUpCode operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequestWithoutOptions() {
        let operation = plugin.resendSignUpCode(for: "username")
        XCTAssertNotNil(operation)
    }
    
    /// Test a successful resendSignUpCode call with .email as the destination of AuthCodeDeliveryDetails
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a successful result with .email as the destination of AuthCodeDeliveryDetails
    ///
    func testResendSignupCodeWithSuccess() {
        
        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: nil,
                                                                                             deliveryMedium: .email,
                                                                                             destination: nil)
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )
        
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
    }
    
    /// Test a resendSignUpCode call with empty username
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a failure with validation error
    ///
    func testResendSignupCodeWithEmptyUsername() {

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: nil,
                                                                                             deliveryMedium: .email,
                                                                                             destination: nil)
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )
        
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "", options: nil) { result in
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

    /// Test a resendSignUpCode call with invalid response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a invalid response
    /// - When:
    ///    - I invoke resendSignUpCode with valid username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendSignupCodeWithInvalidResult() {

        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw AuthError.unknown("Unknown error", nil)
            }
        )
        
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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

        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.codeDeliveryFailureException(CodeDeliveryFailureException(message: "Code delivery failure"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        wait(for: [resultExpectation], timeout: networkTimeout)
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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

    /// Test a resendSignUpCode call with InvalidEmailRoleAccessPolicy response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidEmailRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .emailRole as underlyingError
    ///
    func testResendSignupCodeWithInvalidEmailRoleAccessPolicyException() {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidEmailRoleAccessPolicyException(InvalidEmailRoleAccessPolicyException(message: "Invalid email role access policy"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
                    XCTFail("Underlying error should be sms role \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a resendSignUpCode call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .smsRole as underlyingError
    ///
    func testResendSignupCodeWithinvalidSmsRoleAccessPolicyException() {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidSmsRoleAccessPolicyException(InvalidSmsRoleAccessPolicyException(message: "Invalid sms role access policy"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
                    XCTFail("Underlying error should be sms role \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
    }

    /// Test a resendSignUpCode call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleTrustRelationshipException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .service error with .smsRole as underlyingError
    ///
    func testResendSignupCodeWithInvalidSmsRoleTrustRelationshipException() {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidSmsRoleTrustRelationshipException(InvalidSmsRoleTrustRelationshipException(message: "Invalid sms role trust relationship"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
                    XCTFail("Underlying error should be sms role \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: networkTimeout)
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidLambdaResponseException(InvalidLambdaResponseException(message: "Invalid lambda response"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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

    /// Test a resendSignUpCode call with LimitExceededException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testResendSignupCodeWithLimitExceededException() {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.limitExceededException(LimitExceededException(message: "limit exceeded"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.unexpectedLambdaException(UnexpectedLambdaException(message: "unexpected lambda"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.userLambdaValidationException(UserLambdaValidationException(message: "user lambda validation exception"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.resendSignUpCode(for: "username", options: nil) { result in
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
