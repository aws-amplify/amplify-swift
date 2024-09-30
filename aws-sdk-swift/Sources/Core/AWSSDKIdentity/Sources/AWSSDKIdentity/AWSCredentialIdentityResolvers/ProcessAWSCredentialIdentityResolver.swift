//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT
@_spi(FileBasedConfig) import AWSSDKCommon

/// The process credential identity resolver resolves credentials from running a command or process.
/// The command to run is sourced from a profile in the AWS config file, using the standard
/// profile selection rules. The profile key the command is read from is "credential_process."
/// E.g.:
///  [default]
///  credential_process=/opt/amazon/bin/my-credential-fetcher --argsA=abc
/// On successfully running the command, the output should be a json data with the following
/// format:
/// {
///     "Version": 1,
///     "AccessKeyId": "accesskey",
///     "SecretAccessKey": "secretAccessKey"
///     "SessionToken": "....",
///     "Expiration": "2019-05-29T00:21:43Z"
/// }
/// Version here identifies the command output format version.
public struct ProcessAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    /// Creates a credentials provider that gets credentials from running a command or process.
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
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .process(
            fileBasedConfiguration: fileBasedConfig,
            profileFileNameOverride: profileName
        ))
    }
}
