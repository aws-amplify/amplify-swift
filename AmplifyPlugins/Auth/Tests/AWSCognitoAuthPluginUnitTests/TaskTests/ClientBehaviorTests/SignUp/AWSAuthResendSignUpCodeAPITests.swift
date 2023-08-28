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
import ClientRuntime

class AWSAuthResendSignUpCodeAPITests: AWSCognitoAuthClientBehaviorTests {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: .init())
            }
        )
    }

    /// Test resendSignUpCode operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequest() async throws {
        let pluginOptions = ["somekey": "somevalue"]
        let options = AuthResendSignUpCodeRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.resendSignUpCode(for: "username", options: options)
    }

    /// Test resendSignUpCode operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resendSignUpCode operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResendSignupCodeRequestWithoutOptions() async throws {
        _ = try await plugin.resendSignUpCode(for: "username", options: nil)
    }

    /// Test a successful resendSignUpCode call with .email as the destination of AuthCodeDeliveryDetails
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a successful result with .email as the destination of AuthCodeDeliveryDetails
    ///
    func testResendSignupCodeWithSuccess() async throws {

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: nil,
                                                                                             deliveryMedium: .email,
                                                                                             destination: nil)
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )

        let authCodeDeliveryDetails = try await plugin.resendSignUpCode(for: "username", options: nil)
        guard case .email = authCodeDeliveryDetails.destination else {
            XCTFail("Result should be .email for the destination of AuthCodeDeliveryDetails")
            return
        }
    }

    /// Test a resendSignUpCode call with empty username
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke resendSignUpCode with username
    /// - Then:
    ///    - I should get a failure with validation error
    ///
    func testResendSignupCodeWithEmptyUsername() async throws {

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: nil,
                                                                                             deliveryMedium: .email,
                                                                                             destination: nil)
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                ResendConfirmationCodeOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )

        do {
            _ = try await plugin.resendSignUpCode(for: "", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
        }
    }

    /// Test a resendSignUpCode call with invalid response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a invalid response
    /// - When:
    ///    - I invoke resendSignUpCode with valid username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendSignupCodeWithInvalidResult() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw AuthError.unknown("Unknown error", nil)
            }
        )

        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error")
                return
            }
        }
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
    func testResendSignupCodeWithCodeDeliveryFailureException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw SdkError.service(
                    ResendConfirmationCodeOutputError.codeDeliveryFailureException(
                        .init()),
                    .init(body: .empty, statusCode: .accepted))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeDelivery = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codedelivery \(error)")
                return
            }
        }
    }

    /// Test a resendSignUpCode call with InternalErrorException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke resendSignUpCode with a valid username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendSignupCodeWithInternalErrorException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.internalErrorException(InternalErrorException(message: "internal error"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithInvalidEmailRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidEmailRoleAccessPolicyException(InvalidEmailRoleAccessPolicyException(message: "Invalid email role access policy"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .emailRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms role \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithinvalidSmsRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidSmsRoleAccessPolicyException(InvalidSmsRoleAccessPolicyException(message: "Invalid sms role access policy"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms role \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithInvalidSmsRoleTrustRelationshipException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidSmsRoleTrustRelationshipException(InvalidSmsRoleTrustRelationshipException(message: "Invalid sms role trust relationship"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms role \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithInvalidLambdaResponseException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidLambdaResponseException(InvalidLambdaResponseException(message: "Invalid lambda response"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithInvalidParameterException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.invalidParameterException(InvalidParameterException(message: "invalid parameter"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithLimitExceededException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.limitExceededException(LimitExceededException(message: "limit exceeded"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .limitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be limitExceeded \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithNotAuthorizedException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.notAuthorizedException(NotAuthorizedException(message: "not authorized"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithResourceNotFoundException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.resourceNotFoundException(ResourceNotFoundException(message: "resource not found"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be resourceNotFound \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithTooManyRequestsException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.tooManyRequestsException(TooManyRequestsException(message: "too many requests"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithUnexpectedLambdaException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.unexpectedLambdaException(UnexpectedLambdaException(message: "unexpected lambda"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
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
    func testResendSignupCodeWithUserLambdaValidationException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.userLambdaValidationException(UserLambdaValidationException(message: "user lambda validation exception"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
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
    func testResendSignupCodeUpWithUserNotFoundException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockResendConfirmationCodeOutputResponse: { _ in
                throw ResendConfirmationCodeOutputError.userNotFoundException(UserNotFoundException(message: "user not found"))
            }
        )
        do {
            _ = try await plugin.resendSignUpCode(for: "username", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

}
