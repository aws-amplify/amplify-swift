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

class AuthenticationProviderConfirmSigninTests: XCTestCase {

    var authenticationProvider: AuthenticationProviderAdapter!
    var mockAWSMobileClient: MockAWSMobileClient!
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        mockAWSMobileClient = MockAWSMobileClient()
        authenticationProvider = AuthenticationProviderAdapter(awsMobileClient: mockAWSMobileClient!)
        plugin = AWSCognitoAuthPlugin()
        plugin?.configure(authenticationProvider: authenticationProvider,
                         authorizationProvider: MockAuthorizationProviderBehavior(),
                         userService: MockAuthUserServiceBehavior(),
                         deviceService: MockAuthDeviceServiceBehavior(),
                         hubEventHandler: MockAuthHubEventBehavior())
    }

    func testSuccessfulSignIn() {

        let mockSigninResult = SignInResult(signInState: .signedIn)
        mockAWSMobileClient?.confirmSignInMockResult = .success(mockSigninResult)

        let resultExpectation = expectation(description: "Should receive a result")
        let options = AuthConfirmSignInRequest.Options()
        _ = plugin.confirmSignIn(challengeResponse: "reponse", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignInResult):
                guard case .done = confirmSignInResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

}
