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
import AWSClientRuntime

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class UpdateMFAPreferenceTaskTests: BasePluginTest {

    /// Test a successful updateMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulUpdatePreference() async {

        let allSMSPreferences: [MFAPreference] = [.disabled, .enabled, .preferred, .notPreferred]
        let allTOTPPreference: [MFAPreference] = [.disabled, .enabled, .preferred, .notPreferred]

        // Test all the combinations for preference types
        for smsPreference in allSMSPreferences {
            for totpPreference in allTOTPPreference {
                self.mockIdentityProvider = MockIdentityProvider(
                    mockGetUserAttributeResponse: { request in
                        return .init(
                            userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                        )
                    },
                    mockSetUserMFAPreferenceResponse: { request in
                        XCTAssertEqual(
                            request.smsMfaSettings,
                            smsPreference.smsSetting())
                        XCTAssertEqual(
                            request.softwareTokenMfaSettings,
                            totpPreference.softwareTokenSetting())

                        return .init()
                    })

                do {
                    try await plugin.updateMFAPreference(
                        sms: smsPreference,
                        totp: totpPreference)
                } catch {
                    XCTFail("Received failure with error \(error)")
                }
            }
        }
    }

    // MARK: Service error handling test

    /// Test a updateMFAPreference call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testUpdateMFAPreferenceWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSClientRuntime.UnknownAWSHTTPServiceError(
                    httpResponse: .init(body: .empty, statusCode: .ok),
                    message: nil,
                    requestID: nil,
                    requestID2: nil,
                    typeName: nil
                )
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a updateMFAPreference call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InvalidParameterException response
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    -  I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testUpdateMFAPreferenceWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidParameterException()
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
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

    /// Test a updateMFAPreference call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a NotAuthorizedException response
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    -  I should get a .service error with  .notAuthorized as underlyingError
    ///
    func testUpdateMFAPreferenceWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "message")
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a updateMFAPreference call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testUpdateMFAPreferenceWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
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

    /// Test a updateMFAPreference call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testUpdateMFAPreferenceWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.ResourceNotFoundException()
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a updateMFAPreference call with ForbiddenException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ForbiddenException response
    ///
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testUpdateMFAPreferenceWithForbiddenException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.ForbiddenException()
            }
        )

        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
        }
    }

    /// Test a updateMFAPreference call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testUpdateMFAPreferenceWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotConfirmedException()
            }
        )
        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
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

    /// Test a updateMFAPreference call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke updateMFAPreference
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testUpdateMFAPreferenceWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            },
            mockSetUserMFAPreferenceResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotFoundException()
            }
        )
        do {
            _ = try await plugin.updateMFAPreference(sms: .enabled, totp: .enabled)
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
