//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

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
        
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            UpdateUserAttributesOutputResponse(codeDeliveryDetailsList: [
                .init(attributeName: "attributeName",
                      deliveryMedium: .email,
                      destination: "destination")])
        })
        

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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            UpdateUserAttributesOutputResponse()
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.aliasExistsException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.codeDeliveryFailureException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.codeMismatchException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.expiredCodeException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.unknown(.init(httpResponse: .init(body: .empty, statusCode: .ok)))
        })
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
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.invalidEmailRoleAccessPolicyException(.init())
        })
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
                guard case .emailRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be email role \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)    }

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
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.invalidLambdaResponseException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.invalidParameterException(.init())
        })
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
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.invalidSmsRoleAccessPolicyException(.init())
        })
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
                guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be sms exists \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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
        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.invalidSmsRoleTrustRelationshipException(.init())
        })
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
                guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be sms role \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)    }

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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.notAuthorizedException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.passwordResetRequiredException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.resourceNotFoundException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.tooManyRequestsException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.unexpectedLambdaException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.userLambdaValidationException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.userNotConfirmedException(.init())
        })
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

        mockIdentityProvider = MockIdentityProvider(mockUpdateUserAttributeResponse: { _ in
            throw UpdateUserAttributesOutputError.userNotFoundException(.init())
        })
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
