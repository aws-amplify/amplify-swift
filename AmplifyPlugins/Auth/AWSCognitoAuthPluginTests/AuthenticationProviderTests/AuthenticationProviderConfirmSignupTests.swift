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

class AuthenticationProviderConfirmSignupTests: XCTestCase {

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

        let mockSignupResult = SignUpResult(signUpState: .confirmed, codeDeliveryDetails: nil)
        mockAWSMobileClient?.confirmSignUpMockResult = .success(mockSignupResult)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.confirmSignUp(for: "username",
                                 confirmationCode: "code",
                                 options: AuthConfirmSignUpRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let confirmSignupResult):
                guard case .done = confirmSignupResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(confirmSignupResult.isSignupComplete, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

}
