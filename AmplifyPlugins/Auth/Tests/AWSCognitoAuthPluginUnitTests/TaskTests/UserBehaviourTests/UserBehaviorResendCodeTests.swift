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
import AWSCognitoIdentityProvider
import ClientRuntime

class UserBehaviorResendCodeTests: BasePluginTest {

    /// Test a successful resendConfirmationCode call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a successful result with .email as the attribute's destination
    ///
    func testSuccessfulResendConfirmationCode() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            GetUserAttributeVerificationCodeOutputResponse(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })

        let attribute = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
        guard case .email = attribute.destination else {
            XCTFail("Result should be .email for attributeKey")
            return
        }
    }

    /// Test a resendConfirmationCode call with invalid result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a invalid response
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendConfirmationCodeWithInvalidResult() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            GetUserAttributeVerificationCodeOutputResponse()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testResendConfirmationCodeWithCodeMismatchException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw try await AWSCognitoIdentityProvider.CodeDeliveryFailureException(
                httpResponse: .init(body: .empty, statusCode: .accepted),
                decoder: nil,
                message: nil,
                requestID: nil
            )
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeDelivery = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testResendConfirmationCodeWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.InternalErrorException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testResendConfirmationCodeWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
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

    /// Test a resendConfirmationCode call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .limitExceeded as underlyingError
    ///
    func testResendConfirmationCodeWithLimitExceededException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.LimitExceededException()
        })

        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
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

    /// Test a resendConfirmationCode call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testResendConfirmationCodeWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testResendConfirmationCodeWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testResendConfirmationCodeWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
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

    /// Test a resendConfirmationCode call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testResendConfirmationCodeWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
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

    /// Test a resendConfirmationCode call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testResendConfirmationCodeWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.UserNotConfirmedException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotConfirmed \(error)")
                return
            }
        }
    }

    /// Test a resendConfirmationCode call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke resendConfirmationCode
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testResendConfirmationCodeWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutputResponse: { _ in
            throw AWSCognitoIdentityProvider.UserNotFoundException()
        })
        do {
            _ = try await plugin.resendConfirmationCode(forUserAttributeKey: .email)
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
