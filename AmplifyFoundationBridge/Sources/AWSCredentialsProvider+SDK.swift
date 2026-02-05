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

extension AWSCredentialsProvider where Self: AwsCommonRuntimeKit.CredentialsProviding {
    public func getCredentials() async throws -> AwsCommonRuntimeKit.Credentials {
        let credentials = try await resolve()
        return try credentials.toAWSSDKCredentials()
    }
}


extension AWSCredentialsProvider where Self: AWSCredentialIdentityResolver {
    public func getIdentity(identityProperties: Smithy.Attributes? = nil) async throws -> AWSCredentialIdentity {
        let credentials = try await resolve()
        return try credentials.toAWSCredentialIdentity()
    }
}
