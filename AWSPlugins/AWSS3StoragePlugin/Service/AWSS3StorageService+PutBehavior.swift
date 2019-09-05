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

    public func execute(_ request: AWSS3StoragePutRequest, identityId: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void) {

        let uploadExpression = AWSS3TransferUtilityUploadExpression()
        uploadExpression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        let completionHandler = { (task: AWSS3TransferUtilityUploadTask, error: Error?) -> Void in
            if let HTTPResponse = task.response {
                if HTTPResponse.statusCode != 200 {
                    onEvent(StorageEvent.failed(StoragePutError.httpStatusError(
                        "status code \(HTTPResponse.statusCode)", "Check the status code")))
                    return
                }
            }
            if let error = error {
                onEvent(StorageEvent.failed(StoragePutError.unknown(error.localizedDescription, "TODO")))
            } else {
                onEvent(StorageEvent.completed(StoragePutResult(key: request.key)))
            }
        }

        let continuationBlock = { (task: AWSTask<AWSS3TransferUtilityUploadTask>) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StoragePutError.unknown(error.localizedDescription, "test")))
            } else if let uploadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(uploadTask)))
            } else {
                onEvent(StorageEvent.failed(StoragePutError.unknown("Failed to ", "")))
            }

            return nil
        }

        // TODO: MultiUpload

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key)

        if let fileURL = request.fileURL {
            let task = transferUtility.uploadFile(fileURL,
                                                  bucket: request.bucket,
                                                  key: serviceKey,
                                                  contentType: request.contentType ?? "application/octet-stream",
                                                  expression: uploadExpression,
                                                  completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        } else {
            let task = transferUtility.uploadData(
                request.data!,
                bucket: request.bucket,
                key: serviceKey,
                contentType: request.contentType ?? "application/octet-stream",
                expression: uploadExpression,
                completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        }
    }
}
