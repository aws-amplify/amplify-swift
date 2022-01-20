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
@testable import AWSMobileClient

class AuthenticationProviderDeleteUserTests: BaseAuthenticationProviderTest {

    func testDeleteUserSuccess() {
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                print("Delete user success")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
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
    func testDeleteUserInternalErrorException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.internalError(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithInvalidParameterException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.invalidParameter(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce invalidParameter error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithNotAuthorizedException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.notAuthorized(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithPasswordResetRequiredException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.passwordResetRequired(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .passwordResetRequired = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithResourceNotFoundException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.resourceNotFound(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithTooManyRequestsException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.tooManyRequests(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithUserNotConfirmedException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.userNotConfirmed(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userNotConfirmed error instead of \(error)")
                    return
                }
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
    func testDeleteUserWithUserNotFoundException() {
        mockAWSMobileClient.deleteUserMockError = AWSMobileClientError.userNotFound(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userNotFound error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a deleteUser clears private session after signin via privatesession
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke deleteUser on a private session
    /// - Then:
    ///    - I should get a successful response and user defaults should clear the private session
    ///
    func testSuccessfulDeleteUserWithPrivateSession() {
        let mockSigninResult = UserState.signedIn
        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: .preferPrivateSession()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
                XCTAssertTrue(self.mockUserDefault.isPrivateSessionPreferred(),
                              "Prefer private session userdefaults should be set.")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)

        let deleteUserResultExpectation = expectation(description: "Should receive a result")
        _ = plugin.deleteUser { result in
            defer {
                deleteUserResultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTAssertFalse(self.mockUserDefault.isPrivateSessionPreferred(),
                              "Prefer private session userdefaults should be set to false.")
            case .failure(let error):
                guard case .unknown(_, let underlyingError) = error,
                      case .canceledLogin = (underlyingError as? SFAuthenticationError)?.code else {
                    XCTFail("Should produce SFAuthenticationError error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [deleteUserResultExpectation], timeout: apiTimeout)
    }

    var window: UIWindow {
        let window = UIWindow()
        window.rootViewController = MockRootUIViewController()
        return window
    }
}
