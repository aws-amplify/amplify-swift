//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify

class AWSAPICategoryPluginBaseTests: XCTestCase {

    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        AWSAPICategoryPluginBaseTests.initializeMobileClient()

        Amplify.reset()
        let plugin = AWSAPICategoryPlugin()

        let amplifyConfig = AmplifyConfiguration(api: IntegrationTestConfiguration.apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    // MARK: - Utilities

    static func initializeMobileClient() {
        let callbackInvoked = DispatchSemaphore(value: 1)

        AWSMobileClient.default().initialize { userState, error in
            if let error = error {
                XCTFail("Error initializing AWSMobileClient. Error: \(error.localizedDescription)")
                return
            }

            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }

            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            print("AWSMobileClient Initialized")
            callbackInvoked.signal()
        }

        _ = callbackInvoked.wait(timeout: .now() + networkTimeout)
    }

    func signIn(username: String, password: String) {
        let signInWasSuccessful = expectation(description: "signIn was successful")
        AWSMobileClient.sharedInstance().signIn(username: username, password: password) { result, error in
            if let error = error {
                XCTFail("Sign in failed: \(error.localizedDescription)")
                return
            }

            guard let result = result else {
                XCTFail("No result from SignIn")
                return
            }
            XCTAssertEqual(result.signInState, .signedIn)
            signInWasSuccessful.fulfill()
        }
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    func signUpUser(username: String, password: String) {
        let signUpExpectation = expectation(description: "successful sign up expectation.")
        let userAttributes = ["email": username]
        AWSMobileClient.default().signUp(username: username, password: password, userAttributes: userAttributes) { result, error in

            if let error = error as? AWSMobileClientError {
                XCTFail("Failed to sign up user with error: \(error.message)")
                return
            }

            guard result != nil else {
                XCTFail("result from signUp should not be nil")
                return
            }

            signUpExpectation.fulfill()
        }

        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }
}
