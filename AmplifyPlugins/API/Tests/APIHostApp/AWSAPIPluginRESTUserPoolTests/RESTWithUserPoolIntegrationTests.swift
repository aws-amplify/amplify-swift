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
        if try await isSignedIn() {
            await signOut()
        }
        await Amplify.reset()
    }
    
    func testSetUp() {
        XCTAssertTrue(true)
    }

    func testCreateUser() async throws {
        try await createAuthenticatedUser()
    }
    
    func testCreateUserAndGetToken() async throws {
        try await createAuthenticatedUser()
        let session = try await Amplify.Auth.fetchAuthSession()
        // Get cognito user pool token
        if let cognitoTokenProvider = session as? AuthCognitoTokensProvider {
            let tokens = try cognitoTokenProvider.getCognitoTokens().get()
            print("Id token - \(tokens.idToken) ")
            print("Access token - \(tokens.accessToken) ")
        }
    }
    
    func testGetAPISuccess() async throws {
        try await createAuthenticatedUser()
        let request = RESTRequest(path: "/items")
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        print(result)
    }

    func testGetAPIWithQueryParamsSuccess() async throws {
        try await createAuthenticatedUser()
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello@email.com",
                                    "created": "2021-06-18T09:00:00Z"
                                  ])
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        print(result)
    }

    func testGetAPIWithEncodedQueryParamsSuccess() async throws {
        try await createAuthenticatedUser()
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello%40email.com",
                                    "created": "2021-06-18T09%3A00%3A00Z"
                                  ])
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        print(result)
    }

    func testGetAPIFailedWithSignedOutError() async throws {
        await signOut()
        let request = RESTRequest(path: "/items")
        do {
            _ = try await Amplify.API.get(request: request)
            XCTFail("Should have caught error")
        } catch {
            guard let apiError = error as? APIError else {
                XCTFail("Should be APIError")
                return
            }
            
            guard case let .operationError(_, _, underlyingError) = apiError else {
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
        }
    }
    
    // MARK: - Auth Helpers
    
    func createAuthenticatedUser() async throws {
        if try await isSignedIn() {
            await signOut()
        }
        try await signUp()
        try await signIn()
    }
    
    func isSignedIn() async throws -> Bool {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        return authSession.isSignedIn
    }
    
    func signUp() async throws {
        let signUpResult = try await Amplify.Auth.signUp(username: username, password: password)
        guard signUpResult.isSignUpComplete else {
            XCTFail("Sign up successful but not complete")
            return
        }
    }

    
    func signIn() async throws {
        let signInResult = try await Amplify.Auth.signIn(username: username,
                                               password: password)
        guard signInResult.isSignedIn else {
            XCTFail("Sign in successful but not complete")
            return
        }
    }
    
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }
}
