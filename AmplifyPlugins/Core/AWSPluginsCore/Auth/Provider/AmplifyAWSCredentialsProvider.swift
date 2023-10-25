//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AwsCommonRuntimeKit
import Foundation

public struct _AmplifyAWSCredentialsProvider: CredentialsProvider {
    public func fetchCredentials() async throws -> Credentials {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let credentials = try awsCredentialsProvider.getAWSCredentials().get()
            return .init(
                accessKey: credentials.accessKeyId,
                secret: credentials.secretAccessKey,
                expirationTimeout: (credentials as? AWSTemporaryCredentials)?.expiration,
                sessionToken: (credentials as? AWSTemporaryCredentials)?.sessionToken
            )
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }
    }
}

public class AmplifyAWSCredentialsProvider: AWSClientRuntime.CredentialsProviding {

    public func getCredentials() async throws -> AWSClientRuntime.AWSCredentials {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let awsCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let credentials = try awsCredentialsProvider.getAWSCredentials().get()
            return credentials.toAWSSDKCredentials()
        } else {
            let error = AuthError.unknown("Auth session does not include AWS credentials information")
            throw error
        }
    }
}

extension AWSCredentials {

    func toAWSSDKCredentials() -> AWSClientRuntime.AWSCredentials {
        if let tempCredentials = self as? AWSTemporaryCredentials {
            return AWSClientRuntime.AWSCredentials(
                accessKey: tempCredentials.accessKeyId,
                secret: tempCredentials.secretAccessKey,
                expirationTimeout: tempCredentials.expiration,
                sessionToken: tempCredentials.sessionToken)
        } else {
            return AWSClientRuntime.AWSCredentials(
                accessKey: accessKeyId,
                secret: secretAccessKey,
                expirationTimeout: Date())
        }

    }
}
