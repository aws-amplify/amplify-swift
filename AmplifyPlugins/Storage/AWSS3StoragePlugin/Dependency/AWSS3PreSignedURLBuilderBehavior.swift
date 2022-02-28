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

enum AWSS3HttpMethod {
    case get
    case put
}

enum AWSS3PreSignedURLBuilderError: Error {
    case failed(reason: String, error: Error?)
}

// Behavior that the implemenation class for AWSS3PreSignedURLBuilder will use.
protocol AWSS3PreSignedURLBuilderBehavior {

    /// Gets a pre-signed URL.
    /// - Returns: Pre-Signed URL
    func getPreSignedURL(key: String, method: AWSS3HttpMethod, expires: Int64?) -> URL?

}

extension AWSS3PreSignedURLBuilderBehavior {

    func getPreSignedURL(key: String, method: AWSS3HttpMethod) -> URL? {
        getPreSignedURL(key: key, method: method, expires: nil)
    }

    func getPreSignedURL(key: String) -> URL? {
        getPreSignedURL(key: key, method: .get, expires: nil)
    }

}
