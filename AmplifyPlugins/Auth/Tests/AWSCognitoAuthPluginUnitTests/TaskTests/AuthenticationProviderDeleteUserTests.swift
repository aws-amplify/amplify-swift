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
import ClientRuntime
import AWSClientRuntime
import AwsCommonRuntimeKit

class AuthenticationProviderDeleteUserTests: BasePluginTest {

    func testDeleteUserSuccess() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                try await DeleteUserOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
        do {
            try await plugin.deleteUser()
            print("Delete user success")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test a deleteUser when sign out failed
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   sign out failure
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should still be able to get a success for delete user
    ///
    func testSignOutFailureWhenDeleteUserIsSuccess() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                throw AWSCognitoIdentityProvider.UnsupportedTokenTypeException()
            }, mockGlobalSignOutResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException()
            },
            mockDeleteUserOutputResponse: { _ in
                try await DeleteUserOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
        do {
            try await plugin.deleteUser()
            print("Delete user success")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }


    /// Test a deleteUser with network error from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   network error
    ///
    /// - When:
    ///    - I invoke deleteUser
    /// - Then:
    ///    - I should get a .service error with .network as underlying error
    ///
    func testOfflineDeleteUser() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw CommonRunTimeError.crtError(CRTError(code: 1059))
            }
        )
        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .network = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce network error instead of \(error)")
                return
            }
        }
    }

    /// Test a deleteUser with network error from service and retry with success on no network error
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   network error for the first call and mock an actual result on the second call
    ///
    /// - When:
    ///    - I invoke deleteUser and retry it
    /// - Then:
    ///    - I should get a .service error with .network as underlying error for the first call
    ///    - I should get a valid response for the second call
    ///
    func testOfflineDeleteUserAndRetry() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw CommonRunTimeError.crtError(CRTError(code: 1059))
            }
        )
        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .network = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce network error instead of \(error)")
                return
            }
        }

        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                try await DeleteUserOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }
        )
        do {
            try await plugin.deleteUser()
            print("Delete user success")
        } catch {
            XCTFail("Received failure with error \(error)")
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSClientRuntime.UnknownAWSHTTPServiceError(
                    httpResponse: .init(body: .empty, statusCode: .badRequest),
                    message: nil,
                    requestID: nil,
                    typeName: nil
                )
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.InvalidParameterException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce invalidParameter error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.PasswordResetRequiredException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.ResourceNotFoundException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.TooManyRequestsException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce unknown error instead of \(error)")
                return
            }
        }
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
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotConfirmedException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotConfirmed error instead of \(error)")
                return
            }
        }
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
    ///      AuthN should be in signedOut state
    ///
    func testDeleteUserWithUserNotFoundException() async {
        mockIdentityProvider = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                try await RevokeTokenOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            }, mockGlobalSignOutResponse: { _ in
                try await GlobalSignOutOutputResponse(httpResponse: .init(body: .empty, statusCode: .ok))
            },
            mockDeleteUserOutputResponse: { _ in
                throw AWSCognitoIdentityProvider.UserNotFoundException()
            }
        )

        do {
            try await plugin.deleteUser()
            XCTFail("Should not get success")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error,
                  case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotFound error but instead produced \(error)")
                return
            }
        }

        switch await plugin.authStateMachine.currentState {
        case .configured(let authNState, let authZState):
            switch (authNState, authZState) {
            case (.signedOut, .configured):
                print("AuthN and AuthZ are in a valid state")
            default:
                XCTFail("AuthN should be in signed out state")
            }
        default:
            XCTFail("Auth should be in configured state")

        }
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

