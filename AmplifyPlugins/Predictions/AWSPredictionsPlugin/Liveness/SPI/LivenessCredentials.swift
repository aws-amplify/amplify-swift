//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

func credential(from credentialsProvider: AWSCredentialsProvider?) async throws -> SigV4Signer.Credential {
    let credential: SigV4Signer.Credential

    if let credentialsProvider = credentialsProvider {
        let providedCredentials = try await credentialsProvider.fetchAWSCredentials()
        credential = .init(
            accessKey: providedCredentials.accessKeyId,
            secretKey: providedCredentials.secretAccessKey,
            sessionToken: (providedCredentials as? AWSTemporaryCredentials)?.sessionToken
        )
    } else {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let authAWSCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let awsCredentials = try authAWSCredentialsProvider.getAWSCredentials().get()
            credential = .init(
                accessKey: awsCredentials.accessKeyId,
                secretKey: awsCredentials.secretAccessKey,
                sessionToken: (awsCredentials as? AWSTemporaryCredentials)?.sessionToken
            )
        } else {
            throw FaceLivenessSessionError.accessDenied
        }
    }

    return credential
}
