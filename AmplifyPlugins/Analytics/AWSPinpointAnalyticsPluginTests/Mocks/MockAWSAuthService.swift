//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify

@testable import AWSPinpointAnalyticsPlugin

// This should be moved over to common test package https://github.com/aws-amplify/amplify-ios/issues/21
public class MockAWSAuthService: AWSAuthServiceBehavior {

    var getIdentityIdError: AuthError?
    var identityId: String?

    public func configure() {
    }

    public func reset() {
    }

    public func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        let cognitoCredentialsProvider = AWSCognitoCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, AuthError> {
        if let error = getIdentityIdError {
            return .failure(error)
        }

        return .success(identityId ?? "IdentityId")
    }
}
