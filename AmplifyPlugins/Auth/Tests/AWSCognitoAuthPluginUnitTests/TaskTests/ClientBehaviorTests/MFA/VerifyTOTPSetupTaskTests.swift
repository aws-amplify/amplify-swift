//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class VerifyTOTPSetupTaskTests: BasePluginTest {

    /// Test a successful verify TOTP  setup call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke verifyTOTPSetup
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulVerifyTOTPSetupRequest() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                XCTAssertEqual(request.userCode, "123456")
                XCTAssertEqual(request.friendlyDeviceName, "device")
                return .init(session: "session", status: .success)
            })

        do {
            let pluginOptions = VerifyTOTPSetupOptions(friendlyDeviceName: "device")
            try await plugin.verifyTOTPSetup(
                code: "123456", options: .init(pluginOptions: pluginOptions))
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }


//case invalidUserPoolConfigurationException(InvalidUserPoolConfigurationException)

    // MARK: Service error handling test

    /// Test a verifyTOTPSetup call with forbiddenException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   forbiddenException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error
    ///
    func testVerifyTOTPSetupWithForbiddenException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .forbiddenException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            XCTAssertNil(underlyingError)
        }

    }

    /// Test a verifyTOTPSetup call with internalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   internalErrorException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error
    ///
    func testVerifyTOTPSetupWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .internalErrorException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")

        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }

    }

    /// Test a verifyTOTPSetup call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke verifyTOTPSetup
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testVerifyTOTPSetupWithInvalidParameterException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .invalidParameterException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
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

    /// Test a verifyTOTPSetup call with notAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   notAuthorizedException response
    ///
    /// - When:
    ///    - I invoke verifyTOTPSetup
    /// - Then:
    ///    - I should get a .service error
    ///
    func testVerifyTOTPSetupWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .notAuthorizedException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized(_, _, _) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with SoftwareTokenMFANotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response
    ///
    /// - When:
    ///    - I invoke verifyTOTPSetup
    /// - Then:
    ///    - I should get a .service error with .softwareTokenMFANotEnabled as underlyingError
    ///
    func testVerifyTOTPSetupWithSoftwareTokenMFANotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .softwareTokenMFANotFoundException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .mfaMethodNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be softwareTokenMFANotEnabled \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with resourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   resourceNotFoundException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithResourceNotFoundException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .resourceNotFoundException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with unknown response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   unknown response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service
    ///
    func testVerifyTOTPSetupWithUnknownException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .unknown(.init(httpResponse: .init(body: .empty, statusCode: .ok)))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithCodeMismatchException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .codeMismatchException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with EnableSoftwareTokenMFAException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   EnableSoftwareTokenMFAException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithEnableSoftwareTokenMFAException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .enableSoftwareTokenMFAException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
        }
    }

    /// Test a verifyTOTPSetup call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithPasswordResetRequiredException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .passwordResetRequiredException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
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

    /// Test a verifyTOTPSetup call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithTooManyRequestsException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .tooManyRequestsException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
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

    /// Test a verifyTOTPSetup call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithUserNotFoundException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .userNotFoundException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
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

    /// Test a verifyTOTPSetup call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithUserNotConfirmedException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .userNotConfirmedException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
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

    /// Test a verifyTOTPSetup call with InvalidUserPoolConfigurationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response
    /// - When:
    ///    - I invoke verifyTOTPSetup with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testVerifyTOTPSetupInWithInvalidUserPoolConfigurationException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockVerifySoftwareTokenResponse: { request in
                throw VerifySoftwareTokenOutputError
                    .invalidUserPoolConfigurationException(.init(message: "Exception"))
            })

        do {
            let _ = try await plugin.verifyTOTPSetup(code: "123456", options: nil)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

}
