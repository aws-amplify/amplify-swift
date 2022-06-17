//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSPluginsCore
import Amplify
import XCTest

class AWSAuthCognitoSessionTests: XCTestCase {

    /// Given: a JWT token
    /// When: expiring in 2 mins
    /// Then: method should return the correct state
    func testExpiringTokens() {

        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        let error = AuthError.unknown("", nil)
        let tokens = AWSCognitoUserPoolTokens(idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              refreshToken: "refreshToken",
                                              expiresIn: 121)

        let session = AWSAuthCognitoSession(isSignedIn: true,
                                            identityIdResult: .failure(error),
                                            awsCredentialsResult: .failure(error),
                                            cognitoTokensResult: .success(tokens))
        let cognitoTokens = try! session.getCognitoTokens().get()
        XCTAssertFalse(cognitoTokens.doesExpire(in: 120))
        XCTAssertTrue(cognitoTokens.doesExpire(in: 122))
        XCTAssertFalse(cognitoTokens.doesExpire())
    }

    /// Given: a JWT token
    /// When: that has expired
    /// Then: method should return the correct state
    func testExpiredTokens() {

        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 1).timeIntervalSince1970)
        ]
        let error = AuthError.unknown("", nil)
        let tokens = AWSCognitoUserPoolTokens(idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              refreshToken: "refreshToken",
                                              expiresIn: 121)

        let session = AWSAuthCognitoSession(isSignedIn: true,
                                            identityIdResult: .failure(error),
                                            awsCredentialsResult: .failure(error),
                                            cognitoTokensResult: .success(tokens))

        let cognitoTokens = try! session.getCognitoTokens().get()
        XCTAssertFalse(cognitoTokens.doesExpire())
    }

}
