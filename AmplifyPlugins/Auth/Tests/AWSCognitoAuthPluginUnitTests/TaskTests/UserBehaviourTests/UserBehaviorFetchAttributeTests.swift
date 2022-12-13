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

class UserBehaviorFetchAttributesTests: BasePluginTest {

    /// Test a successful fetchUserAttributes call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a successful result
    ///
    func testSuccessfulFetchUserAttributes() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            GetUserOutputResponse(
                mfaOptions: [],
                preferredMfaSetting: "",
                userAttributes: [.init(name: "email", value: "Amplify@amazon.com")],
                userMFASettingList: [],
                username: ""
            )
        })

        let attributes = try await plugin.fetchUserAttributes()
        XCTAssertEqual(attributes[0].key, AuthUserAttributeKey(rawValue: "email"))
        XCTAssertEqual(attributes[0].value, "Amplify@amazon.com")
    }

    /// Test a fetchUserAttributes call with invalid result
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock an invalid response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testFetchUserAttributesWithInvalidResult() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            GetUserOutputResponse()
        })
        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.unknownError else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    // MARK: Service error handling test

    /// Test a fetchUserAttributes call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testFetchUserAttributesWithInternalErrorException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.unknown(.init(httpResponse: .init(body: .empty, statusCode: .ok)))
        })

        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.unknownError else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InvalidParameterException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    -  I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testFetchUserAttributesWithInvalidParameterException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.invalidParameterException(.init())
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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

    /// Test a fetchUserAttributes call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a NotAuthorizedException response
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    -  I should get a .service error with  .notAuthorized as underlyingError
    ///
    func testFetchUserAttributesWithNotAuthorizedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.notAuthorizedException(.init())
        })

        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.notAuthorizedError else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
    }

    /// Test a fetchUserAttributes call with PasswordResetRequiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired as underlyingError
    ///
    func testFetchUserAttributesWithPasswordResetRequiredException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.passwordResetRequiredException(.init())
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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

    /// Test a fetchUserAttributes call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testFetchUserAttributesWithResourceNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.resourceNotFoundException(.init())
        })

        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard let authError = error as? AuthError, authError.type == AuthError.serviceError else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (authError.underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be passwordResetRequired \(error)")
                return
            }
        }
    }

    /// Test a fetchUserAttributes call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testFetchUserAttributesWithTooManyRequestsException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.tooManyRequestsException(.init())
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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

    /// Test a fetchUserAttributes call with UserNotConfirmedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed as underlyingError
    ///
    func testFetchUserAttributesWithUserNotConfirmedException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.userNotConfirmedException(.init())
        })
        do {
            _ = try await plugin.fetchUserAttributes()
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

    /// Test a fetchUserAttributes call with UserNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke fetchUserAttributes
    /// - Then:
    ///    - I should get a .service error with .userNotFound as underlyingError
    ///
    func testFetchUserAttributesWithUserNotFoundException() async throws {

        mockIdentityProvider = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            throw GetUserOutputError.userNotFoundException(.init())
        })
        do {
            _ = try await plugin.fetchUserAttributes()
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
