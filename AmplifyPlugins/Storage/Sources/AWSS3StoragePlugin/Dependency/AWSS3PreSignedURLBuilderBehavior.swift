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

/// - Tag: AWSS3PreSignedURLBuilderError
enum AWSS3PreSignedURLBuilderError: Error {

    /// Returned by an implementation of a
    /// [AWSS3PreSignedURLBuilderBehavior](x-source-tag://AWSS3PreSignedURLBuilderBehavior)
    ///
    /// - Tag: AWSS3PreSignedURLBuilderError.failed
    case failed(reason: String, error: Error?)
}

/// Behavior that the implemenation class for AWSS3PreSignedURLBuilder will use.
///
/// - Tag: AWSS3PreSignedURLBuilderBehavior
protocol AWSS3PreSignedURLBuilderBehavior {

    /// Attempts to generate a pre-signed URL.
    ///
    /// - Parameters:
    ///     - key: String represnting the key of an S3 object.
    ///     - signingOperation: [AWSS3SigningOperation](x-source-tag://AWSS3SigningOperation)
    ///                    (get, put, upload part) for which the URL will be generated.
    ///     - accelerate: Optional boolean indicating wether or not to enable S3 bucket
    ///                [transfer acceleration](https://docs.amplify.aws/lib/storage/transfer-acceleration/q/platform/js/)
    ///     - expires: Int64 indicating the expiration as the number of milliseconds since the 1970 epoc.
    /// - Returns: Pre-Signed URL
    ///
    /// - Tag: AWSS3PreSignedURLBuilderBehavior.getPreSignedURL
    func getPreSignedURL(key: String,
                         signingOperation: AWSS3SigningOperation,
                         accelerate: Bool?,
                         expires: Int64?) async throws -> URL

}
