//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore

class SignedOutAuthSessionTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        super.tearDown()
        AuthSessionHelper.clearSession()
        await Amplify.reset()
    }

    /// Test if we can fetch auth session in signedOut state
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetch() {
        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let operation = Amplify.Auth.fetchAuthSession { event in
            switch event {
            case .success(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
            authSessionExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }

    /// Test if we can retreive valid credentials for a signedOut session.
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetchWithCredentials() {
        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let operation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .success(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")

            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
            authSessionExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }

    /// Test if we can retreive valid credentials for a signedOut session multiple times
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession multiple times
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testMultipleSuccessfulSessionFetchWithCredentials() {
        let firstAuthSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let firstOperation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .success(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")

            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
            firstAuthSessionExpectation.fulfill()
        }

        let secondAuthSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let secondOperation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .success(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")

            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
            secondAuthSessionExpectation.fulfill()
        }
        XCTAssertNotNil(firstOperation, "Operation should not be nil")
        XCTAssertNotNil(secondOperation, "Operation should not be nil")
        wait(for: [firstAuthSessionExpectation, secondAuthSessionExpectation], timeout: networkTimeout)
    }

    /// Test whether fetchAuth returns signedOut error
    ///
    /// - Given: Auth plugin with user signedOut
    /// - When:
    ///    - I fetchAuth session
    /// - Then:
    ///    - I should get a session with token result as signedOut.
    ///
    func testCognitoTokenSignedOutError() {

        let authSessionExpectation = expectation(description: "Received event result from fetchAuth")
        let operation = Amplify.Auth.fetchAuthSession {event in
            switch event {
            case .success(let result):
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")

                let tokensResult = (result as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case let .failure(authError) = tokensResult,
                      case .signedOut = authError
                else {
                    XCTFail("Should produce signedOut error.")
                    return
                }
            case .failure(let error):
                XCTFail("Should not receive error \(error)")
            }
            authSessionExpectation.fulfill()
        }
        XCTAssertNotNil(operation, "Operation should not be nil")
        wait(for: [authSessionExpectation], timeout: networkTimeout)
    }
}
