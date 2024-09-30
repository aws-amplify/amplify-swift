//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT

/// A credential identity resolver that resolves credentials from the following environment variables:
/// - `AWS_ACCESS_KEY_ID`
/// - `AWS_SECRET_ACCESS_KEY`
/// - `AWS_SESSION_TOKEN`
public struct EnvironmentAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    public init() throws {
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .environment())
    }
}
