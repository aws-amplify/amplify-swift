//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import ClientRuntime
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT
@_spi(FileBasedConfig) import AWSSDKCommon

// swiftlint:disable type_name
// ^ Required to mute swiftlint warning about type name being too long.

/// A credential identity resolver that uses the default AWS credential identity resolver chain used by most AWS SDKs.
/// This is the default resolver when no credential identity resolver is provided by the user.
///
/// The chain resolves the credential identity in the following order:
/// 1. Environment
/// 2. Profile
/// 3. Web Identity Tokens (STS Web Identity)
/// 4. ECS (IAM roles for tasks)
/// 5. EC2 Instance Metadata (IMDSv2)
///
/// The credentials retrieved from the chain are cached for 15 minutes.
public struct DefaultAWSCredentialIdentityResolverChain: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    /// Creates a credential identity resolver that uses the default AWS credential identity resolver chain used by most AWS SDKs.
    public init() throws {
        let fileBasedConfig = try CRTFileBasedConfiguration()
        try self.init(fileBasedConfig: fileBasedConfig)
    }

    @_spi(DefaultAWSCredentialIdentityResolverChain)
    public init(fileBasedConfig: CRTFileBasedConfiguration) throws {
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .defaultChain(
            bootstrap: SDKDefaultIO.shared.clientBootstrap,
            fileBasedConfiguration: fileBasedConfig
        ))
    }
}

// swiftlint:enable type_name
