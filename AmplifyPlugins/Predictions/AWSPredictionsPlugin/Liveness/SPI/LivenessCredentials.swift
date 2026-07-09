//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

func credential(from credentialsProvider: AWSCredentialsProvider?) async throws -> SigV4Signer.Credential {
    let credentials: AWSCredentials

    if let credentialsProvider {
        let providedCredentials = try await credentialsProvider.fetchAWSCredentials()
        credentials = providedCredentials
    } else {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        if let authAWSCredentialsProvider = authSession as? AuthAWSCredentialsProvider {
            let awsCredentials = try authAWSCredentialsProvider.getAWSCredentials().get()
            credentials = awsCredentials
        } else {
            throw FaceLivenessSessionError.accessDenied
        }
    }

    let sessionToken = temporarySessionToken(from: credentials)

    let signerCredential = SigV4Signer.Credential(
        accessKey: credentials.accessKeyId,
        secretKey: credentials.secretAccessKey,
        sessionToken: sessionToken
    )

    return signerCredential
}

private func temporarySessionToken(from credentials: AWSCredentials) -> String? {
    if let temporaryCredentials = credentials as? AWSTemporaryCredentials {
        return temporaryCredentials.sessionToken
    }

    let mirror = Mirror(reflecting: credentials)
    for child in mirror.children {
        if child.label == "sessionToken",
           let value = child.value as? String,
           !value.isEmpty {
            return value
        }
    }

    return nil
}
