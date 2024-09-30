//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import ClientRuntime
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT

/// A credentials provider that uses IMDSv2 to fetch credentials within an EC2 instance.
public struct IMDSAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider
    /// Creates a credentials provider that sources credentials from ec2 instance metadata.
    /// It will use IMDSv2 to fetch the credentials.
    public init() throws {
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(
            source: .imds(
                bootstrap: SDKDefaultIO.shared.clientBootstrap
            )
        )
    }
}
