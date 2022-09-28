//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AwsCommonRuntimeKit

public class AmplifyAWSCredentialsProvider: CredentialsProvider {

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
                secret: tempCredentials.secretKey,
                expirationTimeout: UInt64(tempCredentials.expiration.timeIntervalSinceNow),
                sessionToken: tempCredentials.sessionKey)
        } else {
            return AWSClientRuntime.AWSCredentials(
                accessKey: accessKeyId,
                secret: secretKey,
                expirationTimeout: 0)
        }

    }
}
