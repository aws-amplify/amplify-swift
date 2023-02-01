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
class AuthenticationProviderSignupTests: BaseAuthenticationProviderTest {

    /// Test a successful signup call with .done as next step
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke signup with username and password
    /// - Then:
    ///    - I should get a successful result with .done
    ///
    func testSignupWithSuccess() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let signupResult):
                guard case .done = signupResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signupResult.isSignupComplete, "Signup result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a successful signup call with an empty username
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke signup with an empty username and password
    /// - Then:
    ///    - I should get an validation error
    ///
    func testSignupWithEmptyUserName() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "", password: "password", options: options) { result in
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

    /// Test a successful signup call with an empty password
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke signup with a valid username and empty password
    /// - Then:
    ///    - I should get an validation error
    ///
    func testSignupWithEmptyPassword() {

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let emailAttribute = AuthUserAttribute(.email, value: "email")
        let options = AuthSignUpRequest.Options(userAttributes: [emailAttribute])

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username", password: nil, options: options) { result in
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

    /// Test a successful signup call that return unconfirmed user
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a successul response
    ///   with unconfirmed user.
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a successful response
    ///    - Response's next step should be .confirmUser
    ///    - Response should contain information for delivery
    ///
    func testSignupWithUnConfirmedUser() {

        let mockEmail = "someemail@email"
        let mockCodeDelivery = UserCodeDeliveryDetails(deliveryMedium: .email,
                                                       destination: mockEmail,
                                                       attributeName: "email")
        let mockSignupResult = SignUpResult(signUpState: .unconfirmed, codeDeliveryDetails: mockCodeDelivery)
        mockAWSMobileClient?.signupMockResult = .success(mockSignupResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success(let signupResult):
                guard case .confirmUser(let details, _) = signupResult.nextStep else {
                    XCTFail("Result should be .confirmUser for next step")
                    return
                }

                guard case .email(let deliveryDestination) = details?.destination else {
                    XCTFail("Destination should be .email for next step")
                    return
                }

                guard case .email = details?.attributeKey else {
                    XCTFail("Verifying attribute is email")
                    return
                }
                XCTAssertFalse(signupResult.isSignupComplete, "Signup result should be complete")
                XCTAssertEqual(deliveryDestination, mockEmail, "Destination of signup should be same")

            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with invalid response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a invalid response
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testSignupWithInvalidResult() {

        mockAWSMobileClient?.signupMockResult = nil
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    // MARK: Service error handling test

    /// Test a signup call with CodeDeliveryFailureException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with .codeDelivery as underlyingError
    ///
    func testSignupWithCodeDeliveryFailureException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.codeDeliveryFailure(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with InternalErrorException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testSignupWithInternalErrorException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.internalError(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with InvalidEmailRoleAccessPolicyException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidEmailRoleAccessPolicyException response
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a --
    ///
    func testSignupWithInvalidEmailRoleAccessPolicyException() {
        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a signup call with InvalidLambdaResponseException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testSignupWithInvalidLambdaResponseException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.invalidLambdaResponse(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with InvalidParameterException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with  invalidParameter as underlyingError
    ///
    func testSignupWithInvalidParameterException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.invalidParameter(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with InvalidPasswordException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with invalidPassword as underlyingError
    ///
    func testSignupWithInvalidPasswordException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.invalidPassword(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with InvalidSmsRoleAccessPolicyException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a
    ///
    func testSignupWithInvalidSmsRoleAccessPolicyException() {

        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a signup call with InvalidSmsRoleTrustRelationshipException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleTrustRelationshipException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with .lambda as invalidParameter
    ///
    func testSignupWithInvalidSmsRoleTrustRelationshipException() {

        // TODO: Not implemented. swiftlint:disable:this todo
    }

    /// Test a signup call with NotAuthorizedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSignupWithNotAuthorizedException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.notAuthorized(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with ResourceNotFoundException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with resourceNotFound as underlyingError
    ///
    func testSignupWithResourceNotFoundException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.resourceNotFound(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with TooManyRequestsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with requestLimitExceeded as underlyingError
    ///
    func testSignupWithTooManyRequestsException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.tooManyRequests(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with UnexpectedLambdaException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with lambda as underlyingError
    ///
    func testSignupWithUnexpectedLambdaException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.unexpectedLambda(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with UserLambdaValidationException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with lambda as underlyingError
    ///
    func testSignupWithUserLambdaValidationException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.userLambdaValidation(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a signup call with UsernameExistsException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UsernameExistsException response
    ///
    /// - When:
    ///    - I invoke signup with a valid username and password
    /// - Then:
    ///    - I should get a .service error with lambda as underlyingError
    ///
    func testSignupWithUsernameExistsException() {

        mockAWSMobileClient?.signupMockResult = .failure(AWSMobileClientError.usernameExists(message: "Error"))
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signUp(username: "username",
                          password: "password",
                          options: AuthSignUpRequest.Options()) { result in
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
                guard case .usernameExists = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be usernameExists \(error)")
                    return
                }

            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }
}
