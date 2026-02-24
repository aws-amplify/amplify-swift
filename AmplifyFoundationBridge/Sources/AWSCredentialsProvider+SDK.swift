//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AwsCommonRuntimeKit
import Foundation
import Smithy
import SmithyIdentity

/**
 Converts CRT credentials provider to AWSCredentialsProvider
 */
public extension AWSCredentialsProvider where Self: AwsCommonRuntimeKit.CredentialsProviding {
    func resolve() async throws -> AWSCredentials {
        return try await getCredentials().toAWSCredentials()
    }
}

/**
 Converts Smithy credentials provider AWSCredentialsProvider 
 */
public extension AWSCredentialsProvider where Self: AWSCredentialIdentityResolver {
    func resolve() async throws -> AWSCredentials {
        return try await getIdentity(identityProperties: nil).toAWSCredentials()
    }
}

/**
 Converts AWSCredentialsProvider to CRT credentials provider
 */
public extension AwsCommonRuntimeKit.CredentialsProviding where Self: AWSCredentialsProvider {
    func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        let credentials = try await resolve()
        return try credentials.toAWSSDKCredentials()
    }
}

/**
 Converts AWSCredentialsProvider to Smithy credentials provider
 */
public extension AWSCredentialIdentityResolver where Self: AWSCredentialsProvider {
    func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        let credentials = try await resolve()
        return try credentials.toAWSCredentialIdentity()
    }
}
