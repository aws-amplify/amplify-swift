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

/// A credential identity resolver that resolves credentials from a profile in `~/.aws/config` or the shared credentials file `~/.aws/credentials`.
/// The profile name and the  locations of these files are configurable via the initializer and environment variables
///
/// This resolver supports several credentials formats:
/// ### Credentials defined explicitly within the file
/// ```ini
/// [default]
/// aws_access_key_id = my-access-key
/// aws_secret_access_key = my-secret
/// ```
///
/// ### Assumed role credentials loaded from a credential source
/// ```ini
/// [default]
/// role_arn = arn:aws:iam:123456789:role/RoleA
/// credential_source = Environment
/// ```
///
/// ### Assumed role credentials from a source profile
/// ```ini
/// [default]
/// role_arn = arn:aws:iam:123456789:role/RoleA
/// source_profile = base
///
/// [profile base]
/// aws_access_key_id = my-access-key
/// aws_secret_access_key = my-secret
/// ```
///
/// For more complex configurations see [Configuration and credential file settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
public struct ProfileAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    /// Creates a credential identity resolver that resolves credentials from a profile in `~/.aws/config` or the shared credentials file `~/.aws/credentials`.
    ///
    /// - Parameters:
    ///   - profileName: The profile name to use. If not provided it will be resolved internally via the `AWS_PROFILE` environment variable or defaulted to `default` if not configured.
    ///   - configFilePath: The path to the configuration file to use. If not provided it will be resolved internally via the `AWS_CONFIG_FILE` environment variable or defaulted  to `~/.aws/config` if not configured.
    ///   - credentialsFilePath: The path to the shared credentials file to use. If not provided it will be resolved internally via the `AWS_SHARED_CREDENTIALS_FILE` environment variable or defaulted `~/.aws/credentials` if not configured.
    public init(
        profileName: String? = nil,
        configFilePath: String? = nil,
        credentialsFilePath: String? = nil
    ) throws {
        let fileBasedConfig = try CRTFileBasedConfiguration(
            configFilePath: configFilePath,
            credentialsFilePath: credentialsFilePath
        )
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .profile(
            bootstrap: SDKDefaultIO.shared.clientBootstrap,
            fileBasedConfiguration: fileBasedConfig,
            profileFileNameOverride: profileName
        ))
    }
}
