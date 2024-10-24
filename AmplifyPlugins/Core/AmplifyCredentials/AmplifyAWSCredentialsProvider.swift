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
import Smithy
import SmithyIdentity

public class AmplifyAWSCredentialsProvider: AwsCommonRuntimeKit.CredentialsProviding {

    public func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let credentials = try awsCredentialsProvider.getAWSCredentials().get()
            return try credentials.toAWSSDKCredentials()
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }
    }
}

extension AmplifyAWSCredentialsProvider: AWSCredentialIdentityResolver {
    public func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let credentials = try awsCredentialsProvider.getAWSCredentials().get()
            return try credentials.toAWSCredentialIdentity()
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }
    }
}

extension AWSPluginsCore.AWSCredentials {

    func toAWSSDKCredentials() throws -> AwsCommonRuntimeKit.Credentials {
        if let tempCredentials = self as? AWSTemporaryCredentials {
            return try AwsCommonRuntimeKit.Credentials(
                accessKey: tempCredentials.accessKeyId,
                secret: tempCredentials.secretAccessKey,
                sessionToken: tempCredentials.sessionToken,
                expiration: tempCredentials.expiration
            )
        } else {
            return try AwsCommonRuntimeKit.Credentials(
                accessKey: accessKeyId,
                secret: secretAccessKey,
                expiration: nil
            )
        }

    }

    func toAWSCredentialIdentity() throws -> SmithyIdentity.AWSCredentialIdentity {
        return SmithyIdentity.AWSCredentialIdentity(
            accessKey: accessKeyId,
            secret: secretAccessKey,
            expiration: (self as? AWSTemporaryCredentials)?.expiration,
            sessionToken: (self as? AWSTemporaryCredentials)?.sessionToken
        )
    }
}
