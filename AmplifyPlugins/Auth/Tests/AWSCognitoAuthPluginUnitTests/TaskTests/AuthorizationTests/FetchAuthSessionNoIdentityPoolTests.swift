//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSPluginsCore
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class FetchAuthSessionNoIdentityPoolTests: XCTestCase {

    /// Test fetchAuthSession error mapping for a signed-in user without an identity pool
    ///
    /// - Given: A signed-in session that fails with a `.noIdentityPool` fetch error
    /// - When:
    ///    - The session result is built from that error
    /// - Then:
    ///    - getCognitoTokens() succeeds (user-pool tokens are unaffected)
    ///    - getAWSCredentials() fails (no identity pool configured)
    ///
    func testNoIdentityPoolSessionError_whenSignedIn_preservesUserPoolTokens() async throws {
        let helper = FetchAuthSessionOperationHelper()
        let credentials = AmplifyCredentials.userPoolOnly(signedInData: .testData)
        let error = AuthorizationError.sessionError(.noIdentityPool, credentials)

        let session = try await helper.sessionResultWithError(
            error,
            authenticationState: .signedIn(.testData)
        )

        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        guard case .success = tokensResult else {
            XCTFail("getCognitoTokens() should succeed, got \(String(describing: tokensResult))")
            return
        }

        let awsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
        guard case .failure = awsResult else {
            XCTFail("getAWSCredentials() should fail without an identity pool")
            return
        }
    }

    /// Test that a non-`noIdentityPool` session error keeps its previous behavior
    ///
    /// - Given: A signed-in session that fails with a non-`noIdentityPool` error (`.invalidTokens`)
    /// - When:
    ///    - The session result is built from that error
    /// - Then:
    ///    - getCognitoTokens() still fails, so the fix only diverts the noIdentityPool case
    ///
    func testOtherSessionError_whenSignedIn_stillFailsTokenResult() async throws {
        let helper = FetchAuthSessionOperationHelper()
        let credentials = AmplifyCredentials.userPoolOnly(signedInData: .testData)
        let error = AuthorizationError.sessionError(.invalidTokens, credentials)

        let session = try await helper.sessionResultWithError(
            error,
            authenticationState: .signedIn(.testData)
        )

        let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
        guard case .failure = tokensResult else {
            XCTFail("non-noIdentityPool error should still fail the token result")
            return
        }
    }
}
