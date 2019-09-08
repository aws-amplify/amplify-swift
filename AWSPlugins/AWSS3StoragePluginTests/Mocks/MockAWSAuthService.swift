//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify

@testable import AWSS3StoragePlugin

public class MockAWSAuthService: AWSAuthServiceBehavior {
    public func configure() {
    }

    public func reset() {
    }

    public func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        let cognitoCredentialsProvider = AWSCognitoCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, StorageError> {
        return Result.success("IdentityId")
    }
}
