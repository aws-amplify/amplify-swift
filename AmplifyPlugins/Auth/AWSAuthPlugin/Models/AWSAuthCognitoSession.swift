//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    public let userSubResult: Result<String, AmplifyAuthError>

    public let identityIdResult: Result<String, AmplifyAuthError>

    public let awsCredentialsResult: Result<AuthAWSCredentials, AmplifyAuthError>

    public let cognitoTokensResult: Result<AuthCognitoTokens, AmplifyAuthError>

    init(isSignedIn: Bool,
         userSubResult: Result<String, AmplifyAuthError>,
         identityIdResult: Result<String, AmplifyAuthError>,
         awsCredentialsResult: Result<AuthAWSCredentials, AmplifyAuthError>,
         cognitoTokensResult: Result<AuthCognitoTokens, AmplifyAuthError>) {
        self.isSignedIn = isSignedIn
        self.userSubResult = userSubResult
        self.identityIdResult = identityIdResult
        self.awsCredentialsResult = awsCredentialsResult
        self.cognitoTokensResult = cognitoTokensResult
    }

    public func getAWSCredentials() -> Result<AuthAWSCredentials, AmplifyAuthError> {
        return awsCredentialsResult
    }

    public func getCognitoTokens() -> Result<AuthCognitoTokens, AmplifyAuthError> {
        return cognitoTokensResult
    }

    public func getIdentityId() -> Result<String, AmplifyAuthError> {
        return identityIdResult
    }

    public func getUserSub() -> Result<String, AmplifyAuthError> {
        return userSubResult
    }
}
