//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

extension AWSS3StorageService {

    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        guard let preSignedURL = preSignedURLBuilder.getPreSignedURL(key: serviceKey) else {
            onEvent(.failed(StorageError.unknown("Failed to get pre-signed URL", nil)))
            return
        }
        onEvent(.completed(preSignedURL))
    }

}
