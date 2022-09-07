//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSS3
import ClientRuntime
import AWSClientRuntime

enum AWSS3PreSignedURLBuilderError: Error {
    case failed(reason: String, error: Error?)
}

// Behavior that the implemenation class for AWSS3PreSignedURLBuilder will use.
protocol AWSS3PreSignedURLBuilderBehavior {

    /// Gets a pre-signed URL.
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(key: String, signingOperation: AWSS3SigningOperation, expires: Int64?) async throws -> URL
}

extension AWSS3PreSignedURLBuilderBehavior {

    func getPreSignedURL(key: String, signingOperation: AWSS3SigningOperation, expires: Int64? = nil) async throws -> URL {
        try await getPreSignedURL(key: key, signingOperation: signingOperation, expires: expires)
    }

    func getPreSignedURL(key: String, expires: Int64? = nil) async throws -> URL {
        try await getPreSignedURL(key: key, signingOperation: .getObject, expires: expires)
    }

}
