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

class UserBehaviorConfirmAttributeTests: BasePluginTest {

    /// Test a successful confirmUpdateUserAttributes call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulConfirmUpdateUserAttributes() async throws {
        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            try VerifyUserAttributeOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
        })
        try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
    }

    // MARK: Service error handling test

    /// Test a confirmUpdateUserAttributes call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithCodeMismatchException() async throws {
        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.codeMismatchException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithExpiredCodeException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.expiredCodeException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeExpired = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeExpired \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testcConfirmUpdateUserAttributesWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.internalErrorException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.unknownError else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.invalidParameterException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with LimitExceededException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   LimitExceededException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .limitExceeded error
    ///
    func testConfirmUpdateUserAttributesWithLimitExceededException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.limitExceededException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .limitExceeded = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be limitExceeded \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmUpdateUserAttributesWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.notAuthorizedException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.notAuthorizedError else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.passwordResetRequiredException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .passwordResetRequired = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.resourceNotFoundException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be resourceNotFound \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.tooManyRequestsException(.init())
        })

        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testConfirmUpdateUserAttributesWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.userNotConfirmedException(.init())
        })

        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotConfirmed = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotConfirmed \(error)")
                return
            }
        }
    }

    /// Test a confirmUpdateUserAttributes call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmUpdateUserAttributes with confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmUpdateUserAttributesWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockConfirmUserAttributeOutputResponse: { _ in
            throw VerifyUserAttributeOutputError.userNotFoundException(.init())
        })
        do {
            try await plugin.confirm(userAttribute: .email, confirmationCode: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
        }
    }
}
