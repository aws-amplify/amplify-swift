//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import AWSS3
import Amplify

typealias DeleteCompletedHandler = (AWSTask<AWSS3DeleteObjectOutput>) -> Any?

extension AWSS3StorageService {

    func delete(serviceKey: String, onEvent: @escaping StorageServiceDeleteEventHandler) {
        let request = AWSS3StorageService.makeDeleteObjectRequest(bucket: bucket, serviceKey: serviceKey)
        let deleteCompletedHandler = AWSS3StorageService.makeDeleteCompletedHandler(onEvent: onEvent)

        awsS3.deleteObject(request).continueWith(block: deleteCompletedHandler)
    }

    private static func makeDeleteObjectRequest(bucket: String, serviceKey: String) -> AWSS3DeleteObjectRequest {
        let request: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        request.bucket = bucket
        request.key = serviceKey

        return request
    }

    private static func makeDeleteCompletedHandler(onEvent: @escaping StorageServiceDeleteEventHandler)
        -> DeleteCompletedHandler {

        let block: DeleteCompletedHandler = { (task: AWSTask<AWSS3DeleteObjectOutput>) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let storageError = StorageErrorHelper.mapServiceError(error)
                onEvent(StorageEvent.failed(storageError))
                return nil
            }

            guard task.result != nil else {
                onEvent(StorageEvent.failed(StorageError.unknown("Delete was completed but no result value")))
                return nil
            }

            onEvent(StorageEvent.completedVoid)

            return nil
        }

        return block
    }
}
*/
