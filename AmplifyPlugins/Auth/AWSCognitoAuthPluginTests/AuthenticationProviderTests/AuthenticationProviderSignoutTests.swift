//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSMobileClient

class AuthenticationProviderSignoutTests: BaseAuthenticationProviderTest {

    func testSignOutSuccess() {
        let options = AuthSignOutRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                print("Signout success, with void result")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error

    /// Test a signOut with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignOutWithInternalErrorException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.internalError(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
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

    /// Test a signOut with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testSignOutWithInvalidParameterException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.invalidParameter(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
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

    /// Test a signOut with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a success result
    ///
    func testSignOutWithNotAuthorizedError() {
        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.notAuthorized(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                print("Signout success, with void result")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signOut with `PasswordResetRequiredException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .service error with .passwordResetRequired error
    ///
    func testSignOutWithPasswordResetRequiredException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.passwordResetRequired(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
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

    /// Test a signOut with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testSignOutWithResourceNotFoundException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.resourceNotFound(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
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

    /// Test a signOut with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testSignOutWithTooManyRequestsException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.tooManyRequests(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
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

    /// Test a signOut with `UserNotConfirmedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke signOut
    /// - Then:
    ///    - I should get a .service error with .userNotConfirmed error
    ///
    func testSignOutWithUserNotConfirmedException() {

        let options = AuthSignOutRequest.Options()
        mockAWSMobileClient.signOutMockError = AWSMobileClientError.userNotConfirmed(message: "Error")
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signOut(options: options) { result in
            defer {
                resultExpectation.fulfill()
            }

            switch result {
            case .success:
                XCTFail("Should not get success")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userNotConfirmed = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce unknown error instead of \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

}
