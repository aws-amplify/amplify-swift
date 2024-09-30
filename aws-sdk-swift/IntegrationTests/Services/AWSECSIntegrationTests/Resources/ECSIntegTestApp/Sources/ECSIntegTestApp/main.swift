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
        awsCredentialIdentityResolver: ECSAWSCredentialIdentityResolver()
    )
    let client = STSClient(config: clientConfig)
    let response = try await client.getCallerIdentity(input: GetCallerIdentityInput())
    
    print("Account: \(response.account ?? "No account found!")")
    print("Arn: \(response.arn ?? "No arn found!")")
    print("UserId: \(response.userId ?? "No userId found!")")
    
    if response.account != nil && response.arn != nil && response.userId != nil {
        print("Success!")
    }
}

print("Starting task execution...")
try await executeSTSTask()
print("Task completed.")
