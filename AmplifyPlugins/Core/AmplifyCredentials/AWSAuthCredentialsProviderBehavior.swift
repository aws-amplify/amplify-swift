//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AwsCommonRuntimeKit
import AWSPluginsCore
import SmithyIdentity

public protocol AWSAuthCredentialsProviderBehavior: AWSAuthServiceBehavior {
    func getCredentialsProvider() -> CredentialsProviding

    func getCredentialIdentityResolver() -> any AWSCredentialIdentityResolver
}

