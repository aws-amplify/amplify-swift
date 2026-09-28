//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

/// The credentials a Face Liveness session is signed with: the injected provider's, or else the Auth
/// session's.
///
/// A session without credentials throws the `AuthError` that says why — `invalidState` for a signed-out
/// session, `configuration` when no identity pool is configured, or the session's own error (see
/// `AuthSession.resolveAWSCredentials()`). It used to throw `FaceLivenessSessionError.accessDenied`,
/// which reported a missing sign-in as a Rekognition permissions failure. No `FaceLivenessSessionError`
/// fits instead: every case is a service exception or a URL/region problem, and the type carries no
/// underlying error to say which. A conforming session whose credentials had failed already threw an
/// `AuthError` here, so a caller now sees one error type for every Auth-session credential failure.
func credential(
    from credentialsProvider: AWSCredentialsProvider?,
    fetchAuthSession: () async throws -> AuthSession = { try await Amplify.Auth.fetchAuthSession() }
) async throws -> SigV4Signer.Credential {
    let credentials: AWSCredentials

    if let credentialsProvider {
        let providedCredentials = try await credentialsProvider.fetchAWSCredentials()
        credentials = providedCredentials
    } else {
        let authSession = try await fetchAuthSession()
        credentials = try authSession.resolveAWSCredentials()
    }

    let signerCredential = SigV4Signer.Credential(
        accessKey: credentials.accessKeyId,
        secretKey: credentials.secretAccessKey,
        sessionToken: (credentials as? AWSTemporaryCredentials)?.sessionToken
    )

    return signerCredential
}
