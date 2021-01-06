//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCore

public struct AWSAuthCognitoSession: AuthSession,
    AuthAWSCredentialsProvider,
    AuthCognitoTokensProvider,
AuthCognitoIdentityProvider {

    /// Indicates whether the user is signedIn or not
    public var isSignedIn: Bool

    public let userSubResult: Result<String, AuthError>

    public let identityIdResult: Result<String, AuthError>

    public let awsCredentialsResult: Result<AuthAWSCredentials, AuthError>

    public let cognitoTokensResult: Result<AuthCognitoTokens, AuthError>

    init(isSignedIn: Bool,
         userSubResult: Result<String, AuthError>,
         identityIdResult: Result<String, AuthError>,
         awsCredentialsResult: Result<AuthAWSCredentials, AuthError>,
         cognitoTokensResult: Result<AuthCognitoTokens, AuthError>) {
        self.isSignedIn = isSignedIn
        self.userSubResult = userSubResult
        self.identityIdResult = identityIdResult
        self.awsCredentialsResult = awsCredentialsResult
        self.cognitoTokensResult = cognitoTokensResult
    }

    public func getAWSCredentials() -> Result<AuthAWSCredentials, AuthError> {
        return awsCredentialsResult
    }

    public func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        return cognitoTokensResult
    }

    public func getIdentityId() -> Result<String, AuthError> {
        return identityIdResult
    }

    public func getUserSub() -> Result<String, AuthError> {
        return userSubResult
    }
}
