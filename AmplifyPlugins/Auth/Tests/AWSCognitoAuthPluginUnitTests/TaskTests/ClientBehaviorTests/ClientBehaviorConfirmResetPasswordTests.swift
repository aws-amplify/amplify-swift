//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

class ClientBehaviorConfirmResetPasswordTests: AWSCognitoAuthClientBehaviorTests {

    override func setUp() {
        super.setUp()
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try await ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
    }

    /// Test confirmResetPassword operation can be invoked
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequest() async throws {
        let pluginOptions = ["key": "value"]
        let options = AuthConfirmResetPasswordRequest.Options(pluginOptions: pluginOptions)
        try await plugin.confirmResetPassword(for: "username", with: "password", confirmationCode: "code", options: options)
    }

    /// Test confirmResetPassword operation can be invoked without options
    ///
    /// - Given: Given a configured auth plugin
    /// - When:
    ///    - I call confirmResetPassword operation
    /// - Then:
    ///    - I should get a valid operation object
    ///
    func testConfirmResetPasswordRequestWithoutOptions() async throws {
        try await plugin.confirmResetPassword(for: "username", with: "password", confirmationCode: "code", options: nil)
    }

    /// Test a successful confirmResetPassword call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignup with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulConfirmResetPassword() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try await ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
    }

    /// Test a confirmResetPassword call with empty username
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmResetPassword with an empty username, a new password and a confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmResetPasswordWithEmptyUserName() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try await ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with plugin options
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmResetPassword with an empty username, a new password and a confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmResetPasswordWithPluginOptions() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { request in
                XCTAssertNoThrow(request.clientMetadata)
                XCTAssertEqual(request.clientMetadata?["key"], "value")
                return try await ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        let pluginOptions = AWSAuthConfirmResetPasswordOptions(metadata: ["key": "value"])
        try await plugin.confirmResetPassword(for: "username",
                                              with: "newpassword",
                                              confirmationCode: "code",
                                              options: .init(pluginOptions: pluginOptions))
    }

    /// Test a confirmResetPassword call with empty new password
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, an empty new password and a confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testConfirmResetPasswordWithEmptyNewPassword() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                try await ConfirmForgotPasswordOutputResponse(httpResponse: MockHttpResponse.ok)
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "", confirmationCode: "code", options: nil)
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmResetPasswordWithCodeMismatchException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.CodeMismatchException(message: "code mismatch")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmResetPasswordWithExpiredCodeException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.ExpiredCodeException(message: "code expired")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeExpired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeExpired \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmResetPasswordWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException(message: "internal error")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidLambdaResponseException() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw try await AWSCognitoIdentityProvider.InvalidLambdaResponseException(
                    httpResponse: .init(body: .empty, statusCode: .accepted)
                )
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidParameterException(message: "invalid parameter")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .invalidPassword as underlyingError
    ///
    func testConfirmResetPasswordWithInvalidPasswordException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidPasswordException(message: "invalid password")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidPassword = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidPassword \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testConfirmResetPasswordWithLimitExceededException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.LimitExceededException(message: "limit exceeded")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmResetPasswordWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "not authorized")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .resourceNotFound error
    ///
    func testConfirmResetPasswordWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "resource not found")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be failedAttemptsLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with TooManyFailedAttempts response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyFailedAttemptsException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .failedAttemptsLimitExceeded as underlyingError
    ///
    func testConfirmResetPasswordWithTooManyFailedAttemptsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.TooManyFailedAttemptsException(message: "too many failed attempts")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .failedAttemptsLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be failedAttemptsLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmResetPasswordWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.TooManyRequestsException(message: "too many requests")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithUnexpectedLambdaException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UnexpectedLambdaException(message: "unexpected lambda")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmResetPasswordWithUserLambdaValidationException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserLambdaValidationException(message: "user lambda invalid")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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

    /// Test a confirmResetPassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .userNotConfirmed error
    ///
    func testConfirmResetPasswordWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotConfirmedException(message: "user not confirmed")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }

    /// Test a confirmResetPassword call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmResetPassword with a valid username, a new password and a confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmResetPasswordWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockConfirmForgotPasswordOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotFoundException(message: "user not found")
            }
        )
        do {
            try await plugin.confirmResetPassword(for: "username", with: "newpassword", confirmationCode: "code", options: nil)
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
