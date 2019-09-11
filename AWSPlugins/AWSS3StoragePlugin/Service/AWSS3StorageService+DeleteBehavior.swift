//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

typealias DeleteCompletedHandler = (AWSTask<AWSS3DeleteObjectOutput>) -> Any?

extension AWSS3StorageService {

    func delete(serviceKey: String, onEvent: @escaping StorageDeleteOnEventHandler) {
        let request = AWSS3StorageService.makeDeleteObjectRequest(bucket: bucket, serviceKey: serviceKey)
        let deleteCompletedHandler = AWSS3StorageService.makeDeleteCompletedHandler(onEvent: onEvent,
                                                                                    serviceKey: serviceKey)
        awsS3.deleteObject(request).continueWith(block: deleteCompletedHandler)
    }

    private static func makeDeleteObjectRequest(bucket: String, serviceKey: String) -> AWSS3DeleteObjectRequest {
        let request: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        request.bucket = bucket
        request.key = serviceKey

        return request
    }

    private static func makeDeleteCompletedHandler(onEvent: @escaping StorageDeleteOnEventHandler, serviceKey: String)
        -> DeleteCompletedHandler {

        let block: DeleteCompletedHandler = { (task: AWSTask<AWSS3DeleteObjectOutput>) -> Any? in
            guard task.error == nil else {
                let error = task.error!
                onEvent(StorageEvent.failed(StorageRemoveError.unknown(error.localizedDescription, "TODO")))
                return nil
            }

            if let result = task.result {
                print("delete request result \(result)")
            }

            onEvent(StorageEvent.completed(StorageRemoveResult(key: serviceKey)))

            return nil
        }

        return block
    }
}
