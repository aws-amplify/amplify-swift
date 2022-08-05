//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import AWSClientRuntime
import Amplify
import AWSPluginsCore

public class MockAWSAuthService: AWSAuthServiceBehavior {

    var getIdentityIdError: AuthError?
    var getTokenError: AuthError?
    var getTokenClaimsError: AuthError?
    var identityId: String?
    var token: String?
    var tokenClaims: [String: AnyObject]?

    public func configure() {
    }

    public func reset() {
    }

    public func getCredentialsProvider() -> CredentialsProvider {
        let cognitoCredentialsProvider = MyCustomCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, AuthError> {
        if let error = getIdentityIdError {
            return .failure(error)
        }

        return .success(identityId ?? "IdentityId")
    }

    public func getIdentityID(completion: @escaping (Result<String, AuthError>) -> Void) {
        if let error = getIdentityIdError {
            completion(.failure(error))
        }

        completion(.success(identityId ?? "IdentityId"))
    }
    
    public func getUserPoolAccessToken() async throws -> String {
        if let error = getTokenError {
            throw error
        } else {
            return token ?? "token"
        }
    }

    public func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError> {
        if let error = getTokenClaimsError {
            return .failure(error)
        }
        return .success(tokenClaims ?? ["": "" as AnyObject])
    }
}

struct MyCustomCredentialsProvider: CredentialsProvider {
    func getCredentials() async throws -> AWSCredentials {
        AWSCredentials(accessKey: "AKIDEXAMPLE", secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", expirationTimeout: 30)
    }

    func getCredentials() throws -> SdkFuture<AWSCredentials> {
        let future = SdkFuture<AWSCredentials>()
        future.fulfill(AWSCredentials(accessKey: "AKIDEXAMPLE", secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", expirationTimeout: 30))
        return future
    }
}
