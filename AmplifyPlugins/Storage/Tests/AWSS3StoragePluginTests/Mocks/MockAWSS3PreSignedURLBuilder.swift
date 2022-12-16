//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSS3StoragePlugin
import AWSS3

class MockAWSS3PreSignedURLBuilder {
    var interactions: [String] = []
    var getPreSignedURLHandler: (String, AWSS3SigningOperation, Int64?) -> URL = { _,_,_  in return URL(fileURLWithPath: NSTemporaryDirectory()) }
}

extension MockAWSS3PreSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior {
    func getPreSignedURL(key: String, signingOperation: AWSS3SigningOperation, expires: Int64?) async throws -> URL {
        interactions.append("\(#function) \(key)")
        return getPreSignedURLHandler(key, signingOperation, expires)
    }
}
