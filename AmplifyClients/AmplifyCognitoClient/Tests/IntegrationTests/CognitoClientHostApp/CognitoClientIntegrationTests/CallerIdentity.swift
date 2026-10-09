//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AmplifyFoundation
import AmplifyFoundationBridge
import AWSSTS
import Foundation
import XCTest

/// Signs an STS `GetCallerIdentity` with a session's own credentials, end to end (CR-1, CR-3,
/// MS-5): the client's `credentialsProvider`, wrapped in `FoundationToSDKCredentialsAdapter`, is the SDK
/// client's credential resolver. `GetCallerIdentity` needs no permission, so the permissionless sandbox
/// roles still answer it.
enum CallerIdentity {

    /// The ARN and identity `GetCallerIdentity` returns for `provider`'s credentials.
    static func of(_ provider: any AWSCredentialsProvider, region: String) async throws -> GetCallerIdentityOutput {
        let client = try await STSClient(
            config: STSClient.STSClientConfig(
                awsCredentialIdentityResolver: FoundationToSDKCredentialsAdapter(provider: provider),
                region: region
            )
        )
        return try await client.getCallerIdentity(input: GetCallerIdentityInput())
    }

    /// The assumed-role ARN's role name (`arn:aws:sts::<acct>:assumed-role/<roleName>/<session>`).
    static func roleName(of arn: String) -> String? {
        guard arn.contains(":assumed-role/") else {
            return nil
        }
        return arn.split(separator: "/").dropFirst().first.map(String.init)
    }
}
