//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPICategoryPlugin
import AmplifyPlugins

@testable import Amplify
@testable import AmplifyTestCommon

class RESTWithUserPoolIntegrationTests: XCTestCase {
    struct User {
        let username: String
        let password: String
    }
    let amplifyConfigurationFile = "RESTWithUserPoolIntegrationTests-amplifyconfiguration"
    let credentialsFile = "RESTWithUserPoolIntegrationTests-credentials"
    var user1: User!

    override func setUp() {
        do {

            let credentials = try TestConfigHelper.retrieveCredentials(forResource: credentialsFile)

            guard let user1 = credentials["user1"], let password = credentials["password"] else {
                XCTFail("Missing credentials.json data")
                return
            }
            self.user1 = User(username: user1, password: password)

            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        signOut()
    }

    override func tearDown() {
        signOut()
        Amplify.reset()
    }

    func testGetAPISuccess() {
        signIn(username: user1.username, password: user1.password)
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .success(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetAPIFailedWithSignedOutError() {
        let failedInvoked = expectation(description: "request failed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .success(let data):
                XCTFail("Unexpected .complted event: \(data)")
            case .failure(let error):
                guard case let .operationError(_, _, underlyingError) = error else {
                    XCTFail("Error should be operationError")
                    return
                }

                guard let authError = underlyingError as? AuthError else {
                    XCTFail("underlying error should be AuthError, but instead was \(underlyingError ?? "nil")")
                    return
                }

                guard case .signedOut = authError else {
                    XCTFail("Error should be AuthError.signedOut")
                    return
                }

                failedInvoked.fulfill()
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func signIn(username: String, password: String) {
        let signInInvoked = expectation(description: "sign in completed")
        _ = Amplify.Auth.signIn(username: username, password: password) { event in
            switch event {
            case .success:
                signInInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed to Sign in user \(error)")
            }
        }
        wait(for: [signInInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func signOut() {
        let signOutCompleted = expectation(description: "sign out completed")
        _ = Amplify.Auth.signOut { event in
            switch event {
            case .success:
                signOutCompleted.fulfill()
            case .failure(let error):
                print("Could not sign out user \(error)")
                signOutCompleted.fulfill()
            }
        }
        wait(for: [signOutCompleted], timeout: TestCommonConstants.networkTimeout)
    }
}
