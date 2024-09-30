//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.CredentialsProvider
import ClientRuntime
import enum Smithy.ClientError
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentity.AWSCredentialIdentityResolvedByCRT
import struct Foundation.TimeInterval

// swiftlint:disable type_name
// ^ Required to mute swiftlint warning about type name being too long.

/// A credential identity resolver that uses another resolver to assume a role from the AWS Security Token Service (STS).
///
/// When asked to resolve credentials, this resolver will first invoke the inner credential identity resolver to get AWS credentials for STS.
/// Then, it will call STS to get assumed credentials for the desired role.
///
/// For more information see [Assume role credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-assume-role-credentials.html)
public struct STSAssumeRoleAWSCredentialIdentityResolver: AWSCredentialIdentityResolvedByCRT {
    public let crtAWSCredentialIdentityResolver: AwsCommonRuntimeKit.CredentialsProvider

    /// Creates a credential identity resolver that uses another resolver to assume a role from the AWS Security Token Service (STS).
    ///
    /// - Parameters:
    ///   - awsCredentialIdentityResolver: The underlying credential identity resolver to be used to sign the requests made to STS
    ///   - roleArn: The ARN of the target role to assume, e.g. `arn:aws:iam:123456789:role/example`
    ///   - sessionName: The name to associate with the session. This is used to uniquely identify a session when the same role is assumed by different principals or for different reasons. In cross-account scenarios, the session name is visible to, and can be logged by the account that owns the role. The role session name is also in the ARN of the assumed role principal.
    ///   - durationSeconds: The expiry duration of the STS credentials. Defaults to 15 minutes if not set.
    public init(
        awsCredentialIdentityResolver: any AWSCredentialIdentityResolver,
        roleArn: String,
        sessionName: String,
        durationSeconds: TimeInterval = 900
    ) throws {
        try validateString(name: sessionName, regex: "^[\\w+=,.@-]*$")
        self.crtAWSCredentialIdentityResolver = try AwsCommonRuntimeKit.CredentialsProvider(source: .sts(
            bootstrap: SDKDefaultIO.shared.clientBootstrap,
            tlsContext: SDKDefaultIO.shared.tlsContext,
            credentialsProvider: try awsCredentialIdentityResolver.getCRTAWSCredentialIdentityResolver(),
            roleArn: roleArn,
            sessionName: sessionName,
            duration: durationSeconds
        ))
    }
}

// swiftlint:enable type_name

func validateString(name: String, regex: String) throws {
    guard name.range(of: regex, options: .regularExpression) != nil else {
        throw ClientError.invalidValue("The input value [\(name)] does not match the required regex: \(regex)")
    }
}
