//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPICategoryPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class RESTWithUserPoolIntegrationTests: XCTestCase {

    let amplifyConfigurationFile = "testconfiguration/RESTWithUserPoolIntegrationTests-amplifyconfiguration"

    let username = "integTest\(UUID().uuidString)"
    let password = "P123@\(UUID().uuidString)"
    let email = UUID().uuidString + "@" + UUID().uuidString + ".com"

    override func setUp() async throws {
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        signOut()
    }

    override func tearDown() async throws {
        signOut()
        await Amplify.reset()
    }

    func testGetAPISuccess() {
        registerAndSignIn()
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

    func testGetAPIWithQueryParamsSuccess() {
        registerAndSignIn()
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello@email.com",
                                    "created": "2021-06-18T09:00:00Z"
                                  ])
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

    func testGetAPIWithEncodedQueryParamsSuccess() {
        registerAndSignIn()
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello%40email.com",
                                    "created": "2021-06-18T09%3A00%3A00Z"
                                  ])
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

    // MARK: - Helpers

    func registerAndSignIn() {
        let registerAndSignInComplete = expectation(description: "register and sign in completed")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            if didSucceed {
                registerAndSignInComplete.fulfill()
            } else {
                XCTFail("Failed to Sign in user \(error)")
            }
        }
        wait(for: [registerAndSignInComplete], timeout: TestCommonConstants.networkTimeout)
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
