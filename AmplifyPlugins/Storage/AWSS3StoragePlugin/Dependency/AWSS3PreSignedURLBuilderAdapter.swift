//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import AWSS3

/// The class confirming to AWSS3PreSignedURLBuilderBehavior which uses an instance of the AWSS3PreSignedURLBuilder to
/// perform its methods. This class acts as a wrapper to expose AWSS3PreSignedURLBuilder functionality through an
/// instance over a singleton, and allows for mocking in unit tests. The methods contain no other logic other than
/// calling the same method using the AWSS3PreSignedURLBuilder instance.
class AWSS3PreSignedURLBuilderAdapter: AWSS3PreSignedURLBuilderBehavior {

    let preSignedURLBuilder: AWSS3PreSignedURLBuilder

    /// Creates a pre-signed URL builder.
    /// - Parameter preSignedURLBuilder: Builder which can create a pre-signed URL.
    public init(_ preSignedURLBuilder: AWSS3PreSignedURLBuilder) {
        self.preSignedURLBuilder = preSignedURLBuilder
    }

    /// Gets pre-signed URL.
    /// - Parameter getPreSignedURLRequest: Request.
    /// - Returns: Task.
    public func getPreSignedURL(_ getPreSignedURLRequest: AWSS3GetPreSignedURLRequest) -> AWSTask<NSURL> {
        return preSignedURLBuilder.getPreSignedURL(getPreSignedURLRequest)
    }
}
*/
