//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin
import AWSCognitoAuthPlugin
import AWSPluginsCore

@testable import Amplify
@testable import APIHostApp

class RESTWithUserPoolIntegrationTests: XCTestCase {

    static let amplifyConfigurationFile = "testconfiguration/RESTWithUserPoolIntegrationTests-amplifyconfiguration"

    let username = "integTest\(UUID().uuidString)"
    let password = "P123@\(UUID().uuidString)"
    let email = UUID().uuidString + "@" + UUID().uuidString + ".com"

    override func setUp() async throws {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource:RESTWithUserPoolIntegrationTests.amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        if await isSignedIn() {
            await signOut()
        }
        await Amplify.reset()
    }
    
    func testSetUp() {
        XCTAssertTrue(true)
    }

    func testCreateUser() async {
        await createAuthenticatedUser()
    }
    
    func testCreateUserAndGetToken() async {
        await createAuthenticatedUser()
        let getToken = expectation(description: "get token success")
        Amplify.Auth.fetchAuthSession { result in
            do {
                let session = try result.get()
                // Get cognito user pool token
                if let cognitoTokenProvider = session as? AuthCognitoTokensProvider {
                    let tokens = try cognitoTokenProvider.getCognitoTokens().get()
                    print("Id token - \(tokens.idToken) ")
                    print("Access token - \(tokens.accessToken) ")
                }
                getToken.fulfill()
            } catch {
                XCTFail("shouldn't have failed to get session \(error)")
            }
            
        }
        await waitForExpectations(timeout: 10)
    }
    
    func testGetAPISuccess() async {
        await createAuthenticatedUser()
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

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func testGetAPIWithQueryParamsSuccess() async {
        await createAuthenticatedUser()
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

    func testGetAPIWithEncodedQueryParamsSuccess() async {
        await createAuthenticatedUser()
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

    func testGetAPIFailedWithSignedOutError() async {
        await signOut()
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
    
    // MARK: - Auth Helpers
    
    func createAuthenticatedUser() async {
        if await isSignedIn() {
            await signOut()
        }
        await signUp()
        await signIn()
    }
    
    func isSignedIn() async -> Bool {
        let checkIsSignedInCompleted = expectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        _ = Amplify.Auth.fetchAuthSession { event in
            switch event {
            case .success(let authSession):
                resultOptional = authSession.isSignedIn
                checkIsSignedInCompleted.fulfill()
            case .failure(let error):
                fatalError("Failed to get auth session \(error)")
            }
        }
        await waitForExpectations(timeout: 100)
        guard let result = resultOptional else {
            fatalError("Could not get isSignedIn for user")
        }

        return result
    }
    
    func signUp() async {
        let signUpSuccess = expectation(description: "sign up success")
        _ = Amplify.Auth.signUp(username: username, password: password) { result in
            switch result {
            case .success(let signUpResult):
                if signUpResult.isSignUpComplete {
                    signUpSuccess.fulfill()
                } else {
                    XCTFail("Sign up successful but not complete")
                }
            case .failure(let error):
                XCTFail("Failed to sign up \(error)")
            }
        }
        await waitForExpectations(timeout: 100)
    }

    
    func signIn() async {
        let signInSuccess = expectation(description: "sign in success")
        _ = Amplify.Auth.signIn(username: username,
                                password: password) { result in
            switch result {
            case .success(let signInResult):
                if signInResult.isSignedIn {
                    signInSuccess.fulfill()
                } else {
                    XCTFail("Sign in successful but not complete")
                }
                
            case .failure(let error):
                XCTFail("Failed to sign in \(error)")
            }
        }
        await waitForExpectations(timeout: 100)
    }
    
    func signOut() async {
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
        
        await waitForExpectations(timeout: 100)
    }
}
