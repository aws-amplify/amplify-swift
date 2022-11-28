//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPluginsCore
@testable import AWSS3StoragePlugin

import AWSClientRuntime
import AWSS3
import Amplify
import Foundation

/// Test-friendly implementation of a
/// [AWSAuthServiceBehavior](x-source-tag://AWSAuthServiceBehavior) protocol.
///
/// - Tag: MockAWSAuthServiceBehavior
final class MockAWSAuthServiceBehavior {
    var interactions: [String] = []
    var credentialsProvider = MockCredentialsProvider()
    var tokenClaimsByToken: [String: [String : AnyObject]] = [:]
    var identityID = UUID().uuidString
    var userPoolAccessToken = UUID().uuidString
}

extension MockAWSAuthServiceBehavior: AWSAuthServiceBehavior {
    
    func getCredentialsProvider() -> CredentialsProvider {
        interactions.append(#function)
        return credentialsProvider
    }
    
    func getTokenClaims(tokenString: String) -> Result<[String : AnyObject], AuthError> {
        interactions.append(#function)
        if let claims = tokenClaimsByToken[tokenString] {
            return .success(claims)
        }
        return .failure(.unknown(tokenString))
    }
    
    func getIdentityID() async throws -> String {
        interactions.append(#function)
        return identityID
    }
    
    func getUserPoolAccessToken() async throws -> String {
        interactions.append(#function)
        return userPoolAccessToken
    }
    
}
