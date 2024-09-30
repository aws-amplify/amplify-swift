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

/// A credential identity resolver that exchanges a Web Identity Token for credentials from the AWS Security Token Service (STS).
///
/// It depends on the following values sourced from either environment variables or the configuration file"
/// - region: `AWS_DEFAULT_REGION` environment variable or `region`  in a configuration file
/// - role arn: `AWS_ROLE_ARN` environment variable or `role_arn`  in  a configuration file
/// - role session name: `AWS_ROLE_SESSION_NAME` environment variable or `role_session_name` in a configuration file
/// - token file path: `AWS_WEB_IDENTITY_TOKEN_FILE` environment variable or `web_identity_token_file` in a configuration file
///
/// For more information see [AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
public struct STSWebIdentityAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    /// Creates a credential identity resolver that exchanges a Web Identity Token for credentials from the AWS Security Token Service (STS).
    ///
    /// - Parameters:
    ///   - configFilePath: The path to the configuration file to use. If not provided it will be resolved internally via the `AWS_CONFIG_FILE` environment variable or defaulted  to `~/.aws/config` if not configured.
    ///   - credentialsFilePath: The path to the shared credentials file to use. If not provided it will be resolved internally via the `AWS_SHARED_CREDENTIALS_FILE` environment variable or defaulted `~/.aws/credentials` if not configured.
    ///   - region: (Optional) region override.
    ///   - roleArn: (Optional) roleArn override.
    ///   - roleSessionName: (Optional) roleSessionName override.
    ///   - tokenFilePath: (Optional) tokenFilePath override.
    public init(
        configFilePath: String? = nil,
        credentialsFilePath: String? = nil,
        region: String? = nil,
        roleArn: String? = nil,
        roleSessionName: String? = nil,
        tokenFilePath: String? = nil
    ) throws {
        if let roleSessionName {
            try validateString(name: roleSessionName, regex: "^[\\w+=,.@-]*$")
        }
        let fileBasedConfig = try CRTFileBasedConfiguration(
            configFilePath: configFilePath,
            credentialsFilePath: credentialsFilePath
        )
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .stsWebIdentity(
            bootstrap: SDKDefaultIO.shared.clientBootstrap,
            tlsContext: SDKDefaultIO.shared.tlsContext,
            fileBasedConfiguration: fileBasedConfig,
            region: region,
            roleArn: roleArn,
            roleSessionName: roleSessionName,
            tokenFilePath: tokenFilePath,
            shutdownCallback: nil
        ))
    }
}

// swiftlint:enable type_name
