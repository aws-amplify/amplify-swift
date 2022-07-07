//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSPluginsCore
import AWSClientRuntime
import Foundation

@testable import AWSPinpointAnalyticsPlugin

// This should be moved over to common test package https://github.com/aws-amplify/amplify-ios/issues/21
public class MockAWSAuthService: AWSAuthServiceBehavior {
    var getIdentityIdError: AuthError?
    var getTokenClaimsError: AuthError?
    var identityId: String?
    var tokenClaims: [String: AnyObject]?

    public func configure() {}

    public func reset() {}

    public func getCredentialsProvider() -> CredentialsProvider {
        let cognitoCredentialsProvider = AmplifyAWSCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, AuthError> {
        if let error = getIdentityIdError {
            return .failure(error)
        }

        return .success(identityId ?? "IdentityId")
    }

    public func getToken() -> Result<String, AuthError> {
        .success("")
    }
    
    public func getIdentityID(completion: @escaping (Result<String, AuthError>) -> Void) {
        if let error = getIdentityIdError {
            completion(.failure(error))
        }

        completion(.success(identityId ?? "IdentityId"))
    }
    
    public func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        completion(.success(""))
    }
    
    public func getUserPoolAccessToken() async throws -> String {
        ""
    }

    public func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError> {
        if let error = getTokenClaimsError {
            return .failure(error)
        }
        return .success(tokenClaims ?? ["": "" as AnyObject])
    }
}
