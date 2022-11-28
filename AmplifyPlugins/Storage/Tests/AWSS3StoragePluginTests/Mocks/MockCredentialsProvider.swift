//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import Foundation

/// Test-friendly implementation of a
/// [CredentialsProvider](x-source-tag://CredentialsProvider) protocol.
///
/// - Tag: MockCredentialsProvider
final class MockCredentialsProvider {
    var interactions: [String] = []
    var credentials = AWSCredentials(accessKey: UUID().uuidString,
                                     secret: UUID().uuidString,
                                     expirationTimeout: UInt64.random(in: 1..<100),
                                     sessionToken: UUID().uuidString)
}

extension MockCredentialsProvider: CredentialsProvider {
    func getCredentials() async throws -> AWSClientRuntime.AWSCredentials {
        return credentials
    }
}
