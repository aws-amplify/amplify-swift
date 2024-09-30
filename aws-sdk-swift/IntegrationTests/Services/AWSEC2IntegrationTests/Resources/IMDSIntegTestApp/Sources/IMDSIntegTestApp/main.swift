//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSClientRuntime
import AWSSTS

func executeSTSTask() async throws {
    let clientConfig = try await STSClient.STSClientConfiguration(
        awsCredentialIdentityResolver: IMDSAWSCredentialIdentityResolver(),
        region: "us-west-2"
    )
    let client = STSClient(config: clientConfig)
    let response = try await client.getCallerIdentity(input: GetCallerIdentityInput())
    
    print("Account: \(response.account ?? "No account found!")")
    print("Arn: \(response.arn ?? "No arn found!")")
    print("UserId: \(response.userId ?? "No userId found!")")
    
    let isNotNil = response.account != nil && response.arn != nil && response.userId != nil
    let isNotEmpty = response.account != "" && response.arn != "" && response.userId != ""
    if isNotNil && isNotEmpty {
        print("IMDS integration test completed with the status: imds-integration-test-success")
    } else {
        print("IMDS integration test completed with the status: imds-integration-test-failure")
    }
}

print("Starting IMDS integration test execution...")
do {
    try await executeSTSTask()
} catch {
    print ("IMDS integration test threw an exception: \(error.localizedDescription).")
}
