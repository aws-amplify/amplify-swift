//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient
import AWSPluginsCore
import Foundation

@testable import AWSPinpointAnalyticsPlugin

// This should be moved over to common test package https://github.com/aws-amplify/amplify-ios/issues/21
public class MockAWSAuthService: AWSAuthServiceBehavior {
    var getIdentityIdError: AuthError?
    var identityId: String?

    public func configure() {}

    public func reset() {}

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
        .success("")
    }
}
