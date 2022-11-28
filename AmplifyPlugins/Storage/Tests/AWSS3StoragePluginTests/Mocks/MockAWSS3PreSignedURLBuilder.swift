//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin

import AWSS3
import Foundation

/// Test-friendly implementation of a
/// [AWSS3PreSignedURLBuilderBehavior](x-source-tag://AWSS3PreSignedURLBuilderBehavior)
/// protocol.
///
/// - Tag: MockAWSS3PreSignedURLBuilder
final class MockAWSS3PreSignedURLBuilder {
    var interactions: [String] = []
    var defaultURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingPathComponent(UUID().uuidString))
    var preSignedURLs: [String: URL] = [:]
}

extension MockAWSS3PreSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior {
    func getPreSignedURL(key: String, signingOperation: AWSS3SigningOperation, expires: Int64?) async throws -> URL {
        interactions.append(#function)
        if let url = preSignedURLs[key] {
            return url
        }
        return defaultURL
    }
}
