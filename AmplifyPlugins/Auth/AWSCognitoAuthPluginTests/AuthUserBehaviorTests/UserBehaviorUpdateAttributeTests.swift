//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class UserBehaviorUpdateAttributesTests: BaseUserBehaviorTest {

    /// Test a successful updateUserAttributes call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulUpdateUserAttributes() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .success([UserCodeDeliveryDetails(deliveryMedium: .email,
                                              destination: "destination",
                                              attributeName: "attributeName")])

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let attributes):
                guard case .done = attributes.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a updateUserAttributes call with invalid result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a invalid response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testUpdateUserAttributesWithInvalidResult() {

        mockAWSMobileClient?.updateUserAttributesMockResult = nil

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with aliasExistsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   aliasExistsException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .aliasExists as underlyingError
    ///
    func testUpdateUserAttributesWithAliasExistsException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.aliasExists(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with CodeDeliveryFailureException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeDelivery as underlyingError
    ///
    func testUpdateUserAttributesWithCodeDeliveryFailureException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.codeDeliveryFailure(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testUpdateUserAttributesWithCodeMismatchException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.codeMismatch(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testUpdateUserAttributesWithExpiredCodeException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.expiredCode(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testUpdateUserAttributesWithInternalErrorException() {

        mockAWSMobileClient?.signupMockResult =
            .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with InvalidEmailRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesWithInvalidEmailRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a updateUserAttributes call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithInvalidLambdaResponseException() {
        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testUpdateUserAttributesWithInvalidParameterException() {

        mockAWSMobileClient?.updateUserAttributesMockResult = .failure(
            AWSMobileClientError.invalidParameter(message: "Error")
        )
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesWithinvalidSmsRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a updateUserAttributes call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a --
    ///
    func testUpdateUserAttributesCodeWithInvalidSmsRoleTrustRelationshipException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a updateUserAttributes call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testUpdateUserAttributesWithNotAuthorizedException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testUpdateUserAttributesWithPasswordResetRequiredException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.passwordResetRequired(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testUpdateUserAttributesWithResourceNotFoundException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testUpdateUserAttributesWithTooManyRequestsException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithUnexpectedLambdaException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testUpdateUserAttributesWithUserLambdaValidationException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testUpdateUserAttributesWithUserNotConfirmedException() {

        mockAWSMobileClient?.updateUserAttributesMockResult = .failure(
            AWSMobileClientError.userNotConfirmed(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
       _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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

    /// Test a updateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateUserAttributes with AuthUserAttribute
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testUpdateUserAttributesWithUserNotFoundException() {

        mockAWSMobileClient?.updateUserAttributesMockResult =
            .failure(AWSMobileClientError.userNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.update(userAttribute: AuthUserAttribute(.email, value: "Amplify@amazon.com")) { result in
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
