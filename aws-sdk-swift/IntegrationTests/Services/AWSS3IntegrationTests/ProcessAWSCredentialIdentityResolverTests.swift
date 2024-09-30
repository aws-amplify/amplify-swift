//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSS3
import AWSClientRuntime
import AWSSDKIdentity

// Please provide your-access-key and your-secret-key in Resources/credenitals
class ProcessAWSCredentialIdentityResolverTests: XCTestCase {
        
    var client: S3Client!
        
    override func setUp() async throws {
        // Setup ProcessAWSCredentialIdentityResolver
        let processAWSCredentialIdentityResolver = try ProcessAWSCredentialIdentityResolver(
            configFilePath: Bundle.module.path(forResource: "config", ofType: nil)!,
            credentialsFilePath: Bundle.module.path(forResource: "credentials", ofType: nil)!
        )

        // Setup S3ClientConfiguration to use ProcessAWSCredentialIdentityResolver
        let testConfig = try await S3Client.S3ClientConfiguration()
        testConfig.awsCredentialIdentityResolver = processAWSCredentialIdentityResolver

        // Initialize our S3 client with the specified configuration
        client = S3Client(config: testConfig)
    }

    // This test calls listBuckets() and forces S3Client to use ProcessAWSCredentialIdentityResolver
    // TODO: Re-enable this test once CI is configured to run it.  See https://github.com/awslabs/aws-sdk-swift/issues/1309
    func xtest_listBuckets() async throws {
        _ = try await client.listBuckets(input: ListBucketsInput())
    }
}
