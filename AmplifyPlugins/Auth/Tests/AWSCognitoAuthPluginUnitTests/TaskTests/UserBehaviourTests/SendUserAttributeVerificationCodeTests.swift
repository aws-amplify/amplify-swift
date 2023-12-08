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

class SendUserAttributeVerificationCodeTests: BasePluginTest {

    /// Test a successful sendVerificationCode call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a successful result with .email as the attribute's destination
    ///
    func testSuccessfulSendVerificationCode() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(
                    attributeName: "attributeName",
                    deliveryMedium: .email,
                    destination: "destination"))
        })

        let attribute = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
        guard case .email = attribute.destination else {
            XCTFail("Result should be .email for attributeKey")
            return
        }
    }

    /// Test a sendVerificationCode call with invalid result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a invalid response
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testSendVerificationCodeWithInvalidResult() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            GetUserAttributeVerificationCodeOutput()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error")
                return
            }
        }
    }

    /// Test a sendVerificationCode call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testSendVerificationCodeWithCodeMismatchException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw try await AWSCognitoIdentityProvider.CodeDeliveryFailureException(
                httpResponse: .init(body: .empty, statusCode: .accepted),
                decoder: nil,
                message: nil,
                requestID: nil
            )
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testSendVerificationCodeWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.InternalErrorException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a sendVerificationCode call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testSendVerificationCodeWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .limitExceeded as underlyingError
    ///
    func testSendVerificationCodeWithLimitExceededException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.LimitExceededException()
        })

        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSendVerificationCodeWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.NotAuthorizedException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a sendVerificationCode call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testSendVerificationCodeWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testSendVerificationCodeWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testSendVerificationCodeWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testSendVerificationCodeWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.UserNotConfirmedException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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

    /// Test a sendVerificationCode call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke sendVerificationCode
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testSendVerificationCodeWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeVerificationCodeOutput: { _ in
            throw AWSCognitoIdentityProvider.UserNotFoundException()
        })
        do {
            _ = try await plugin.sendVerificationCode(forUserAttributeKey: .email)
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
