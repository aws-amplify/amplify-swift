//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SafariServices

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

class AuthenticationProviderDeleteUserTests: BasePluginTest {

    func testDeleteUserSuccess() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                try DeleteUserOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            resultExpectation.fulfill()
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service Exceptions

    /// Test a deleteUser with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testDeleteUserInternalErrorException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.unknown(.init(httpResponse: .init(body: .empty, statusCode: .badRequest)))
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testDeleteUserWithInvalidParameterException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.invalidParameterException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce invalidParameter error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testDeleteUserWithNotAuthorizedException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.notAuthorizedException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `PasswordResetRequiredException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired error
    ///
    func testDeleteUserWithPasswordResetRequiredException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.passwordResetRequiredException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testDeleteUserWithResourceNotFoundException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.resourceNotFoundException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testDeleteUserWithTooManyRequestsException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.tooManyRequestsException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `UserNotConfirmedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed error
    ///
    func testDeleteUserWithUserNotConfirmedException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.userNotConfirmedException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotConfirmed error instead of \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser with `UserNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .userNotFound error
    ///
    func testDeleteUserWithUserNotFoundException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw DeleteUserOutputError.userNotFoundException(.init())
            }
        )
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            try await plugin.deleteUser()
            print("Delete user success")
            XCTFail("Should not get success")
        } catch {
            resultExpectation.fulfill()
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotFound error but instead produced \(error)")
                return
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

// TODO: ENABLE TESTS after adding hosted UI feature
    /// Test a deleteUser clears private session after signin via privatesession
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke deleteUser on a private session
    /// - Then:
    ///    - I should get a successful response and user defaults should clear the private session
    ///
//    func testSuccessfulDeleteUserWithPrivateSession() {
//        let mockSigninResult = UserState.signedIn
//        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)
//
//        let resultExpectation = expectation(description: "Should receive a result")
//        _ = plugin.signInWithWebUI(presentationAnchor: window, options: .preferPrivateSession()) { result in
//            defer {
//                resultExpectation.fulfill()
//            }
//            switch result {
//            case .success(let signinResult):
//                guard case .done = signinResult.nextStep else {
//                    XCTFail("Result should be .done for next step")
//                    return
//                }
//                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
//                XCTAssertTrue(self.mockUserDefault.isPrivateSessionPreferred(),
//                              "Prefer private session userdefaults should be set.")
//            case .failure(let error):
//                XCTFail("Received failure with error \(error)")
//            }
//        }
//        wait(for: [resultExpectation], timeout: apiTimeout)
//
//        let deleteUserResultExpectation = expectation(description: "Should receive a result")
//        _ = plugin.deleteUser { result in
//            defer {
//                deleteUserResultExpectation.fulfill()
//            }
//
//            switch result {
//            case .success:
//                XCTAssertFalse(self.mockUserDefault.isPrivateSessionPreferred(),
//                              "Prefer private session userdefaults should be set to false.")
//            case .failure(let error):
//                guard case .unknown(_, let underlyingError) = error,
//                      case .canceledLogin = (underlyingError as? SFAuthenticationError)?.code else {
//                    XCTFail("Should produce SFAuthenticationError error instead of \(error)")
//                    return
//                }
//            }
//        }
//        wait(for: [deleteUserResultExpectation], timeout: apiTimeout)
//    }
//
//    var window: UIWindow {
//        let window = UIWindow()
//        window.rootViewController = MockRootUIViewController()
//        return window
//    }
}
