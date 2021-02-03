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

// swiftlint:disable:next type_name
class AuthenticationProviderSigninWithSocialWebUITests: BaseAuthenticationProviderTest {

    var window: UIWindow {
        let window = UIWindow()
        window.rootViewController = MockRootUIViewController()
        return window
    }

    /// Test a signInWithWebUI with valid inputs
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testSuccessfulSignIn() {

        let mockSigninResult = UserState.signedIn
        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
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
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI that return invalid response
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI with valid values
    ///    - Mock service returns invalid response like `signedOut`
    /// - Then:
    ///    - I should get a .unknown response
    ///
    func testSignInWithInvalidResponse() {

        let mockSigninResult = UserState.signedOut
        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error instead - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Received failure with error \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI when the user cancel
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI and mock cancel using SFAuthenticationError
    /// - Then:
    ///    - I should get a AWSCognitoAuthError.userCancelled error
    ///
    func testCancelSignIn() {
        let mockError = NSError(domain: SFAuthenticationErrorDomain,
                                code: SFAuthenticationError.canceledLogin.rawValue,
                                userInfo: nil)
        mockAWSMobileClient?.showSignInMockResult = .failure(mockError)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userCancelled = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce AWSCognitoAuthError error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI when the user cancel
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI and mock cancel using ASWebAuthenticationSessionError
    /// - Then:
    ///    - I should get a AWSCognitoAuthError.userCancelled error
    ///
    @available(iOS 12.0, *)
    func testASWebAuthenticationSessionError() {
        let mockError = NSError(domain: ASWebAuthenticationSessionErrorDomain,
                                code: ASWebAuthenticationSessionError.canceledLogin.rawValue,
                                userInfo: nil)
        mockAWSMobileClient?.showSignInMockResult = .failure(mockError)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userCancelled = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce AWSCognitoAuthError error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI with secuirty failed error
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI and mock securityFailed
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInSecurityFailed() {

        let error = AWSMobileClientError.securityFailed(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .service = error else {
                    XCTFail("Should produce service error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI with bad request error
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI and mock badRequest
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInBadRequest() {

        let error = AWSMobileClientError.badRequest(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .service = error else {
                    XCTFail("Should produce service error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signInWithWebUI with invalid id token error
    ///
    /// - Given: an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signInWithWebUI and mock idTokenAndAcceessTokenNotIssued
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInInvalidIdToken() {

        let error = AWSMobileClientError.idTokenAndAcceessTokenNotIssued(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(for: .amazon, presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
