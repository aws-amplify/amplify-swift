//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    func getPreSignedURL(serviceKey: String,
                         signingOperation: AWSS3SigningOperation,
                         expires: Int) async throws -> URL {
        return try await preSignedURLBuilder.getPreSignedURL(key: serviceKey, signingOperation: signingOperation, expires: Int64(expires))
    }
}
