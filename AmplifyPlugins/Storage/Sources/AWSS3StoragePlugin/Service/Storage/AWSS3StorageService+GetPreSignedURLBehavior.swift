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
                         signingOperation: AWSS3SigningOperation = .getObject,
                         accelerate: Bool?,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        Task {
            do {
                onEvent(.completed(try await preSignedURLBuilder.getPreSignedURL(key: serviceKey,
                                                                                 signingOperation: signingOperation,
                                                                                 accelerate: accelerate,
                                                                                 expires: Int64(expires))))
            } catch {
                onEvent(.failed(StorageError.unknown("Failed to get pre-signed URL", nil)))
            }
        }
    }
}
