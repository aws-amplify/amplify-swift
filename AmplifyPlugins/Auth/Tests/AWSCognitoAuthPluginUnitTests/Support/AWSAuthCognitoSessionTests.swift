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
                                              refreshToken: "refreshToken")

        let session = AWSAuthCognitoSession(isSignedIn: true,
                                            identityIdResult: .failure(error),
                                            awsCredentialsResult: .failure(error),
                                            cognitoTokensResult: .success(tokens))
        let cognitoTokens = try! session.getCognitoTokens().get() as! AWSCognitoUserPoolTokens
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
                                              refreshToken: "refreshToken")

        let session = AWSAuthCognitoSession(isSignedIn: true,
                                            identityIdResult: .failure(error),
                                            awsCredentialsResult: .failure(error),
                                            cognitoTokensResult: .success(tokens))

        let cognitoTokens = try! session.getCognitoTokens().get() as! AWSCognitoUserPoolTokens
        XCTAssertFalse(cognitoTokens.doesExpire())
    }

    /// Given: An AWSAuthCognitoSession with a valid AWSCognitoUserPoolTokens
    /// When: getUserSub is invoked
    /// Then: The "sub" from the token data should be returned
    func testGetUserSub_shouldReturnResult() {
        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]

        let error = AuthError.unknown("", nil)
        let tokens = AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken"
        )

        let session = AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .failure(error),
            awsCredentialsResult: .failure(error),
            cognitoTokensResult: .success(tokens)
        )

        guard case .success(let userSub) = session.getUserSub() else {
            XCTFail("Unable to retrieve userSub")
            return
        }
        XCTAssertEqual(userSub, "1234567890")
    }

    /// Given: An AWSAuthCognitoSession with a AWSCognitoUserPoolTokens that does not include a "sub" attribute
    /// When: getUserSub is invoked
    /// Then: A .failure with AuthError.unknown error is returned
    func testGetUserSub_withoutSub_shouldReturnError() {
        let tokenData = [
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]

        let error = AuthError.unknown("", nil)
        let tokens = AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken"
        )

        let session = AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .failure(error),
            awsCredentialsResult: .failure(error),
            cognitoTokensResult: .success(tokens)
        )

        guard case .failure(let error) = session.getUserSub(),
              case .unknown(let errorDescription, _) = error else {
            XCTFail("Expected AuthError.unknown")
            return
        }

        XCTAssertEqual(errorDescription, "Could not retreive user sub from the fetched Cognito tokens.")
    }
    
    /// Given: An AWSAuthCognitoSession that is signed out
    /// When: getUserSub is invoked
    /// Then: A .failure with AuthError.signedOut error is returned
    func testGetUserSub_signedOut_shouldReturnError() {
        let error = AuthError.signedOut("", "", nil)
        let session = AWSAuthCognitoSession(
            isSignedIn: false,
            identityIdResult: .failure(error),
            awsCredentialsResult: .failure(error),
            cognitoTokensResult: .failure(error)
        )

        guard case .failure(let error) = session.getUserSub(),
              case .signedOut(let errorDescription, let recoverySuggestion, _) = error else {
            XCTFail("Expected AuthError.signedOut")
            return
        }

        XCTAssertEqual(errorDescription, AuthPluginErrorConstants.userSubSignOutError.errorDescription)
        XCTAssertEqual(recoverySuggestion, AuthPluginErrorConstants.userSubSignOutError.recoverySuggestion)
    }
    
    /// Given: An AWSAuthCognitoSession that has a service error
    /// When: getUserSub is invoked
    /// Then: A .failure with AuthError.signedOut error is returned
    func testGetUserSub_serviceError_shouldReturnError() {
        let serviceError = AuthError.service("Something went wrong", "Try again", nil)
        let session = AWSAuthCognitoSession(
            isSignedIn: false,
            identityIdResult: .failure(serviceError),
            awsCredentialsResult: .failure(serviceError),
            cognitoTokensResult: .failure(serviceError)
        )

        guard case .failure(let error) = session.getUserSub() else {
            XCTFail("Expected AuthError.signedOut")
            return
        }

        XCTAssertEqual(error, serviceError)
    }
    
    /// Given: An AuthAWSCognitoCredentials and an AWSCognitoUserPoolTokens instance
    /// When: Two AWSAuthCognitoSession are created from the same values
    /// Then: The two AWSAuthCognitoSession are considered equal
    func testSessionsAreEqual() {
        let expiration = Date(timeIntervalSinceNow: 121)
        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(expiration.timeIntervalSince1970)
        ]

        let credentials = AuthAWSCognitoCredentials(
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            sessionToken: "sessionToken",
            expiration: expiration
        )

        let tokens = AWSCognitoUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
            refreshToken: "refreshToken"
        )

        let session1 = AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .success("identityId"),
            awsCredentialsResult: .success(credentials),
            cognitoTokensResult: .success(tokens)
        )

        let session2 = AWSAuthCognitoSession(
            isSignedIn: true,
            identityIdResult: .success("identityId"),
            awsCredentialsResult: .success(credentials),
            cognitoTokensResult: .success(tokens)
        )

        XCTAssertEqual(session1, session2)
        XCTAssertEqual(session1.debugDictionary.count, session2.debugDictionary.count)
        for key in session1.debugDictionary.keys where (key != "AWS Credentials" && key != "cognitoTokens") {
            XCTAssertEqual(session1.debugDictionary[key] as? String, session2.debugDictionary[key] as? String)
        }
    }
}
