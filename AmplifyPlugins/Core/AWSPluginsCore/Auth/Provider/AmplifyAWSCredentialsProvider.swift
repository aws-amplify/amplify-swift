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
        try await withCheckedThrowingContinuation { continuation in
            _  = Amplify.Auth.fetchAuthSession { result in
                do {
                    let session = try result.get()
                    if let awsCredentialsProvider = session as? AuthAWSCredentialsProvider {
                        let credentials = try awsCredentialsProvider.getAWSCredentials().get()
                        continuation.resume(with: .success(credentials.toAWSSDKCredentials()))
                    } else {
                        let error = AuthError.unknown("Auth session does not include AWS credentials information")
                        continuation.resume(with: .failure(error))
                    }
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
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
