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

class ClientBehaviorResetPasswordTests: AWSCognitoAuthClientBehaviorTests {

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
    func testResetPasswordRequest() async throws {
        let pluginOptions = ["key": "value"]
        let options = AuthResetPasswordRequest.Options(pluginOptions: pluginOptions)
        _ = try await plugin.resetPassword(for: "username", options: options)
    }

    /// Test resetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call resetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testResetPasswordRequestWithoutOptions() async throws {
        _ = try await plugin.resetPassword(for: "username", options: nil)
    }

    /// Test a successful resetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulResetPassword() async throws {
        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: "attribute",
                                                                                             deliveryMedium: .email,
                                                                                             destination: "Amplify@amazon.com")
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )
        _ = try await plugin.resetPassword(for: "user", options: nil)
    }

    /// Test a resetPassword call with nil UserCodeDeliveryDetails
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResetPasswordWithNilCodeDeliveryDetails() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: nil)
            }
        )

        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a resetPassword call with empty username
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke resetPassword with empty username
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testResetPasswordWithEmptyUsername() async throws {

        let codeDeliveryDetails = CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType(attributeName: "attribute",
                                                                                             deliveryMedium: .email,
                                                                                             destination: "Amplify@amazon.com")
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                ForgotPasswordOutputResponse(codeDeliveryDetails: codeDeliveryDetails)
            }
        )

        do {
            _ = try await plugin.resetPassword(for: "", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
        }
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
    func testResetPasswordWithCodeDeliveryFailureException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.CodeDeliveryFailureException(message: "Code delivery failure")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeDelivery = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeDelivery \(error)")
                return
            }
        }
    }

    /// Test a resetPassword call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResetPasswordWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw try await AWSCognitoIdentityProvider.InternalErrorException(
                    httpResponse: .init(body: .empty, statusCode: .accepted)
                )
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
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
    func testResetPasswordWithInvalidEmailRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidEmailRoleAccessPolicyException(
                    message: "invalid email role"
                )
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .emailRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be limitExceeded \(error)")
                return
            }
        }
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
    func testResetPasswordWithInvalidLambdaResponseException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidLambdaResponseException(message: "Invalid lambda response")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
    func testResetPasswordWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidParameterException(message: "invalid parameter")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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

    /// Test a resetPassword call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke resetPassword with username
    /// - Then:
    ///    - I should get a .smsRole error
    ///
    func testResetPasswordWithInvalidSmsRoleAccessPolicyException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidSmsRoleAccessPolicyException(message: "invalid sms role")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be limitExceeded \(error)")
                return
            }
        }
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
    func testResetPasswordWithInvalidSmsRoleTrustRelationshipException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidSmsRoleTrustRelationshipException(
                    message: "invalid sms role trust relationship"
                )
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be limitExceeded \(error)")
                return
            }
        }
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
    func testResetPasswordWithLimitExceededException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.LimitExceededException(message: "limit exceeded")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
    func testResetPasswordWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "not authorized")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
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
    func testResetPasswordWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "resource not found")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
    func testResetPasswordWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.TooManyRequestsException(message: "too many requests")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
    func testResetPasswordWithUnexpectedLambdaException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UnexpectedLambdaException(message: "unexpected lambda")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
    func testResetPasswordWithUserLambdaValidationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserLambdaValidationException(message: "user lambda validation exception")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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

    /* DISABLED, because userNotConfirmedException was removed from the SDK
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
    */

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
    func testResetPasswordWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotFoundException(message: "user not found")
            }
        )
        do {
            _ = try await plugin.resetPassword(for: "user", options: nil)
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
