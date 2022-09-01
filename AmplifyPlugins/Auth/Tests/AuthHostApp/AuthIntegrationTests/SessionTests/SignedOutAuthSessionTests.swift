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

    override func setUp() {
        super.setUp()
        initializeAmplify()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
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
    func testSuccessfulSessionFetch() async throws {
        let result = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(result.isSignedIn, "Session state should be not signed In")
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
        XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")
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
        XCTAssertNotNil(awsCredentails.accessKey, "Access key should not be nil")

        let secondResult = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(secondResult.isSignedIn, "Session state should be not signed In")
        let credentialsSecondResult = (secondResult as? AuthAWSCredentialsProvider)?.getAWSCredentials()
        guard let awsSecondCredentails = try? credentialsSecondResult?.get() else {
            XCTFail("Could not fetch aws credentials")
            return
        }
        XCTAssertNotNil(awsSecondCredentails.accessKey, "Access key should not be nil")
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
}
