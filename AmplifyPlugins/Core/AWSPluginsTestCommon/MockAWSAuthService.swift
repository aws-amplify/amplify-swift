//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify
import AWSPluginsCore

public class MockAWSAuthService: AWSAuthServiceBehavior {

    var getIdentityIdError: AuthError?
    var getTokenError: AuthError?
    var getTokenClaimsError: AuthError?
    var identityId: String?
    var token: String?
    var tokenClaims: [String : AnyObject]?

    public func configure() {
    }

    public func reset() {
    }

    public func getCredentialsProvider() -> AWSCredentialsProvider {
        let cognitoCredentialsProvider = AWSCognitoCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, AuthError> {
        if let error = getIdentityIdError {
            return .failure(error)
        }

        return .success(identityId ?? "IdentityId")
    }

    public func getToken() -> Result<String, AuthError> {
        if let error = getTokenError {
            return .failure(error)
        }

        return .success(token ?? "token")
    }

    public func getTokenClaims(tokenString: String) -> Result<[String : AnyObject], AuthError> {
        if let error = getTokenClaimsError {
            return .failure(error)
        }
        return .success(tokenClaims ?? ["":"" as AnyObject])
    }
}
