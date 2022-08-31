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

    public func getCredentials() async throws -> AWSCredentials {
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

extension AuthAWSCredentials {

    func toAWSSDKCredentials() -> AWSCredentials {
        if let tempCredentials = self as? AuthAWSTemporaryCredentials {
            return AWSCredentials(accessKey: tempCredentials.accessKey,
                                  secret: tempCredentials.secretKey,
                                  expirationTimeout: UInt64(tempCredentials.expiration.timeIntervalSinceNow),
                                  sessionToken: tempCredentials.sessionKey)
        } else {
            return AWSCredentials(accessKey: accessKey, secret: secretKey, expirationTimeout: 0)
        }

    }
}
