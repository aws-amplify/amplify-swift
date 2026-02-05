//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/**
 Protocol to implement for providers vending AWS credentials
 */
public protocol AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials
}
