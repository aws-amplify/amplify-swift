//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

//public typealias GetURLCompletedHandler = (AWSTask<NSURL>) -> Any?

extension AWSS3StorageService {

    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        do {
            // https://BUCKET.s3.REGION.amazonaws.com/PREFIX+KEY
            guard let bucket = bucket else {
                throw StorageError.unknown("Invalid bucket", nil)
            }
            guard let region = region else {
                throw StorageError.unknown("Invalid region", nil)
            }
            guard let url = URL(string: "https://\(bucket).s3.\(region).amazonaws.com/\(serviceKey)") else {
                throw StorageError.unknown("Failed to create URL for pre-signed URL", nil)
            }
            let urlRequest = URLRequest(url: url)
            let preSignedURL = try preSignedURLBuilder.getPreSignedURL(urlRequest)
            onEvent(.completed(preSignedURL))
        } catch {
            onEvent(.failed(StorageError(error: error)))
        }
    }

}
