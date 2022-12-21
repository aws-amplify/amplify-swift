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
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    /// Test if we can fetch auth session in signedOut state
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetch() async throws {
        let result = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
    }

    /// Test if we can fetch auth session in signedOut state and refresh after a signOut
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    ///    - Then invoke signOut
    ///    - Then call fetchAuthSession again
    /// - Then:
    ///    - Valid response with signedOut state = false and identity Id is different
    ///
    func testSuccessfulSessionFetchAfterSignOut() async throws {

        let result = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoResult = result as? AWSAuthCognitoSession,
              let identityID1 = try? cognitoResult.identityIdResult.get() else {
            XCTFail("Should retreive identity ID")
            return
        }
        _ = await Amplify.Auth.signOut()
        XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")

        let result2 = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoResult = result2 as? AWSAuthCognitoSession,
              let identityID2 = try? cognitoResult.identityIdResult.get() else {
            XCTFail("Should retreive identity ID")
            return
        }
        XCTAssertNotEqual(identityID1, identityID2)
    }

    /// Test if we can retreive valid credentials for a signedOut session.
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testSuccessfulSessionFetchWithCredentials() async throws {
        let result = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
        let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
        guard let awsCredentails = try? credentialsResult?.get() else {
            XCTFail("Could not fetch aws credentials")
            return
        }
        XCTAssertNotNil(awsCredentails.accessKeyId, "Access key should not be nil")
    }

    /// Test if we can retreive valid credentials for a signedOut session multiple times
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession multiple times
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testMultipleSuccessfulSessionFetchWithCredentials() async throws {
        let firstResult = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(firstResult.isSignedIn, "Session state should be not signed In")
        let credentialsResult = (firstResult as? AuthAWSCredentialsProvider)?.getAWSCredentials()
        guard let awsCredentails = try? credentialsResult?.get() else {
            XCTFail("Could not fetch aws credentials")
            return
        }
        XCTAssertNotNil(awsCredentails.accessKeyId, "Access key should not be nil")

        let secondResult = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(secondResult.isSignedIn, "Session state should be not signed In")
        let credentialsSecondResult = (secondResult as? AuthAWSCredentialsProvider)?.getAWSCredentials()
        guard let awsSecondCredentails = try? credentialsSecondResult?.get() else {
            XCTFail("Could not fetch aws credentials")
            return
        }
        XCTAssertNotNil(awsSecondCredentails.accessKeyId, "Access key should not be nil")
    }

    /// Test whether fetchAuth returns signedOut error
    ///
    /// - Given: Auth plugin with user signedOut
    /// - When:
    ///    - I fetchAuth session
    /// - Then:
    ///    - I should get a session with token result as signedOut.
    ///
    func testCognitoTokenSignedOutError() async throws {
        let result = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")

        let tokensResult = (result as? AuthCognitoTokensProvider)?.getCognitoTokens()
        guard case let .failure(authError) = tokensResult,
              case .signedOut = authError
        else {
            XCTFail("Should produce signedOut error.")
            return
        }
    }
    
    // MARK: - Stress tests
    
    /// Test if we can fetch auth session in signedOut state
    ///
    /// - Given: Auth category with a signedOut state
    /// - When:
    ///    - I invoke fetchAuthSession from 50 tasks simulateneously
    /// - Then:
    ///    - Valid response with signedOut state = false
    ///
    func testMultipleFetchAuthSessionWhenSignedOut() async throws {
        let fetchAuthSessionExpectation = asyncExpectation(description: "Session state should not be signedIn",
                                           expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let result = try await Amplify.Auth.fetchAuthSession()
                XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
                let credentialsResult = (result as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard let awsCredentails = try? credentialsResult?.get() else {
                    XCTFail("Could not fetch aws credentials")
                    return
                }
                XCTAssertNotNil(awsCredentails.accessKeyId, "Access key should not be nil")
                await fetchAuthSessionExpectation.fulfill()
            }
        }
        
        await waitForExpectations([fetchAuthSessionExpectation], timeout: networkTimeout)
    }
}
