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
import ClientRuntime
import AWSClientRuntime

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
            guard case AuthError.unknown = error else {
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
            throw try await AWSClientRuntime.UnknownAWSHTTPServiceError(
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: nil,
                requestID: nil,
                requestID2: nil,
                typeName: nil
            )
        })

        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
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
            throw AWSCognitoIdentityProvider.InvalidParameterException()
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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
            throw try await AWSCognitoIdentityProvider.NotAuthorizedException(
                httpResponse: .init(body: .empty, statusCode: .accepted),
                decoder: nil,
                message: nil,
                requestID: nil
            )
        })

        do {
            _ = try await plugin.fetchUserAttributes()
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
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
            throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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
            throw AWSCognitoIdentityProvider.ResourceNotFoundException()
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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
            throw AWSCognitoIdentityProvider.TooManyRequestsException()
        })

        do {
            _ = try await plugin.fetchUserAttributes()
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
            throw AWSCognitoIdentityProvider.UserNotConfirmedException()
        })
        do {
            _ = try await plugin.fetchUserAttributes()
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
            throw AWSCognitoIdentityProvider.UserNotFoundException()
        })
        do {
            _ = try await plugin.fetchUserAttributes()
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
