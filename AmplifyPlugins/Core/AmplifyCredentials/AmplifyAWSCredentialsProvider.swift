//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import AwsCommonRuntimeKit
import AWSPluginsCore
import Foundation
import Smithy
import SmithyIdentity

public class AmplifyAWSCredentialsProvider: AwsCommonRuntimeKit.CredentialsProviding, @unchecked Sendable {

    /// Fetches the auth session, reporting an unconfigured Auth category as a thrown error.
    ///
    /// Reading `Amplify.Auth` with no plugin registered hits a `preconditionFailure`, which aborts the
    /// process rather than failing the request. A credentials provider is reachable from long-lived
    /// clients that can outlive `Amplify.reset()` — the cached `PinpointContext` in `AWSPinpointFactory`
    /// is one, since nothing ever clears it — so this is a state the provider can genuinely be called in,
    /// and it should surface as an error the caller can handle.
    private static func fetchAuthSession() async throws -> AuthSession {
        guard Amplify.Auth.isConfiguredWithPlugin else {
            throw AuthError.configuration(
                "The Auth category is not configured",
                """
                Call Amplify.configure() with a configuration that includes Auth before requesting AWS \
                credentials. This can also happen when a client outlives Amplify.reset() and then makes \
                a request.
                """
            )
        }
        return try await Amplify.Auth.fetchAuthSession()
    }

    public func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        let authSession = try await Self.fetchAuthSession()
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
        let authSession = try await Self.fetchAuthSession()
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
