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
class FetchMFAPreferenceTaskTests: BasePluginTest {

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulPreferenceFetchWithTOTPPreferred() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SOFTWARE_TOKEN_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertEqual(fetchMFAPreferenceResult.enabled, [.totp, .sms])
            XCTAssertEqual(fetchMFAPreferenceResult.preferred, .totp)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulPreferenceFetchWithSMSPreferred() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "SMS_MFA",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertEqual(fetchMFAPreferenceResult.enabled, [.totp, .sms])
            XCTAssertEqual(fetchMFAPreferenceResult.preferred, .sms)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulPreferenceFetchWithNonePreferred() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertEqual(fetchMFAPreferenceResult.enabled, [.totp, .sms])
            XCTAssertNil(fetchMFAPreferenceResult.preferred)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response with an invalid MFA type string
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testInvalidResponseForUserMFASettingsList() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    userMFASettingList: ["DUMMY"]
                )
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAPreferenceResult.enabled)
            XCTAssertNil(fetchMFAPreferenceResult.preferred)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response with an invalid MFA type string
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testInvalidResponseForUserMFAPreference() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init(
                    preferredMfaSetting: "DUMMY",
                    userMFASettingList: ["SOFTWARE_TOKEN_MFA", "SMS_MFA"]
                )
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAPreferenceResult.enabled)
            XCTAssertNil(fetchMFAPreferenceResult.preferred)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a successful fetchMFAPreference call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successful response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulPreferenceFetchWithNonePreferredAndNoneEnabled() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockGetUserAttributeResponse: { request in
                return .init()
            })

        do {
            let fetchMFAPreferenceResult = try await plugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAPreferenceResult.enabled)
            XCTAssertNil(fetchMFAPreferenceResult.preferred)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    // MARK: Service error handling test

    /// Test a fetchMFAPreference call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testFetchMFAPreferenceWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.unknown(.init(httpResponse: .init(body: .empty, statusCode: .ok)))
        })

        do {
            _ = try await plugin.fetchMFAPreference()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchMFAPreference call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InvalidParameterException response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    -  I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testFetchMFAPreferenceWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.invalidParameterException(.init())
        })

        do {
            _ = try await plugin.fetchMFAPreference()
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

    /// Test a fetchMFAPreference call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a NotAuthorizedException response
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    -  I should get a .service error with  .notAuthorized as underlyingError
    ///
    func testFetchMFAPreferenceWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.notAuthorizedException(.init(message: "message"))
        })

        do {
            _ = try await plugin.fetchMFAPreference()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchMFAPreference call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testFetchMFAPreferenceWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.passwordResetRequiredException(.init())
        })

        do {
            _ = try await plugin.fetchMFAPreference()
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

    /// Test a fetchMFAPreference call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testFetchMFAPreferenceWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.resourceNotFoundException(.init())
        })

        do {
            _ = try await plugin.fetchMFAPreference()
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

    /// Test a fetchMFAPreference call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testFetchMFAPreferenceWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.tooManyRequestsException(.init())
        })

        do {
            _ = try await plugin.fetchMFAPreference()
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

    /// Test a fetchMFAPreference call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testFetchMFAPreferenceWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.userNotConfirmedException(.init())
        })
        do {
            _ = try await plugin.fetchMFAPreference()
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

    /// Test a fetchMFAPreference call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchMFAPreference
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testFetchMFAPreferenceWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.userNotFoundException(.init())
        })
        do {
            _ = try await plugin.fetchMFAPreference()
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
