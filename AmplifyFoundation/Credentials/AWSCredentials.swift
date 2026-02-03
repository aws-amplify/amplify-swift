//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public protocol AWSCredentials {
    var accessKeyId: String { get }
    var secretAccessKey: String { get }
}

public protocol AWSTemporaryCredentials: AWSCredentials {
    var sessionToken: String { get }
    var expiration: Date { get }
}

public protocol AWSCredentialsProvider {
    func resolve() async throws -> AWSCredentials
}
