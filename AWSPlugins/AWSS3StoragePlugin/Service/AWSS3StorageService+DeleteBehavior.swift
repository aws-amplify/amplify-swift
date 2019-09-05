//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

extension AWSS3StorageService {

    func delete(bucket: String, serviceKey: String, onEvent: @escaping StorageDeleteOnEventHandler) {
        let request = AWSS3StorageService.makeDeleteObjectRequest(bucket: bucket, serviceKey: serviceKey)

        awsS3.deleteObject(request).continueWith { (task) -> Any? in

            guard task.error == nil else {
                let error = task.error!
                onEvent(StorageEvent.failed(StorageRemoveError.unknown(error.localizedDescription, "TODO")))
                return nil
            }

            onEvent(StorageEvent.completed(StorageRemoveResult(key: serviceKey)))

            return nil
        }
    }

    public static func makeDeleteObjectRequest(bucket: String, serviceKey: String) -> AWSS3DeleteObjectRequest {
        let request: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        request.bucket = bucket
        request.key = serviceKey

        return request
    }
}
