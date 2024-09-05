//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import AwsCommonRuntimeKit
import Foundation
import SmithyIdentity

class MockCredentialsProvider: AwsCommonRuntimeKit.CredentialsProviding, AWSCredentialIdentityResolver {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        return try Credentials(
            accessKey: "accessKey",
            secret: "secret",
            expiration: Date().addingTimeInterval(1000)
        )
    }
}
