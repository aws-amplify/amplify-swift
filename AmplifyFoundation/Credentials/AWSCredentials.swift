//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public protocol FoundationAWSCredentials {
    var accessKeyId: String { get }
    var secretAccessKey: String { get }
}

public protocol FoundationAWSTemporaryCredentials: FoundationAWSCredentials {
    var sessionToken: String { get }
    var expiration: Date { get }
}

public protocol FoundationAWSCredentialsProvider {
    func resolve() async throws -> FoundationAWSCredentials
}
