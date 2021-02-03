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
class AuthenticationProviderSigninWithWebUITests: BaseAuthenticationProviderTest {

    var window: UIWindow {
        let window = UIWindow()
        window.rootViewController = MockRootUIViewController()
        return window
    }

    /// Test a signIn with valid inputs
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testSuccessfulSignIn() {

        let mockSigninResult = UserState.signedIn
        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
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

    /// Test a signIn that return invalid response
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    ///    - Mock service returns invalid response like `signedOut`
    /// - Then:
    ///    - I should get a .unknown response
    ///
    func testSignInWithInvalidResponse() {

        let mockSigninResult = UserState.signedOut
        mockAWSMobileClient?.showSignInMockResult = .success(mockSigninResult)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
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

    /// Test a signIn when the user cancel
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn and mock cancel
    /// - Then:
    ///    - I should get a SFAuthenticationError.canceledLogin error
    ///
    func testCancelSignIn() {
        let mockError = NSError(domain: "com.apple.SafariServices.Authentication",
                                code: SFAuthenticationError.canceledLogin.rawValue,
                                userInfo: nil)
        mockAWSMobileClient?.showSignInMockResult = .failure(mockError)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should throw user cancelled error, instead - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userCancelled = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userCancelled error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with secuirty failed error
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn and mock securityFailed
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInSecurityFailed() {

        let error = AWSMobileClientError.securityFailed(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
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

    /// Test a signIn with bad request error
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn and mock badRequest
    /// - Then:
    ///    - I should get a .service error
    ///
    func testSignInBadRequest() {

        let error = AWSMobileClientError.badRequest(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
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

    /// Test a signIn with invalid id token error
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn and mock idTokenAndAcceessTokenNotIssued
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInInvalidIdToken() {

        let error = AWSMobileClientError.idTokenAndAcceessTokenNotIssued(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)
        let options = AuthWebUISignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: options) { result in
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

    /// Test a signIn with valid inputs and private session
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values and private session as option
    /// - Then:
    ///    - I should get a .done response and user defaults should store private session
    ///
    func testSuccessfulSignInWithPrivateSession() {

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
    }

    /// Test a signIn with error and private session
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn and mock securityFailed
    /// - Then:
    ///    - I should get a .service error and private session should not be set.
    ///
    func testSignInWithPrivateSessionServiceError() {

        let error = AWSMobileClientError.securityFailed(message: "")
        mockAWSMobileClient?.showSignInMockResult = .failure(error)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signInWithWebUI(presentationAnchor: window, options: .preferPrivateSession()) { result in

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
                XCTAssertFalse(self.mockUserDefault.isPrivateSessionPreferred(),
                              "Prefer private session userdefaults should not be set.")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}

class MockRootUIViewController: UIViewController {
    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        completion!()
    }
}
