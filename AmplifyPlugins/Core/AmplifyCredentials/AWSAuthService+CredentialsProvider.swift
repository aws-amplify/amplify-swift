//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AwsCommonRuntimeKit
import AWSPluginsCore
import Foundation
import SmithyIdentity

extension AWSAuthService: AWSAuthCredentialsProviderBehavior {
    public func getCredentialsProvider() -> AwsCommonRuntimeKit.CredentialsProviding {
        return AmplifyAWSCredentialsProvider()
    }

    public func getCredentialIdentityResolver() -> any AWSCredentialIdentityResolver {
        return AmplifyAWSCredentialsProvider()
    }
}
