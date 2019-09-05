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

    public func multiPartUpload(bucket: String,
                                serviceKey: String,
                                key: String,
                                fileURL: URL?,
                                data: Data?,
                                contentType: String?,
                                onEvent: @escaping StorageMultiPartUploadOnEventHandler) {

        let uploadExpression = AWSS3TransferUtilityUploadExpression()
        uploadExpression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        let onCompletedHandler = { (task: AWSS3TransferUtilityUploadTask, error: Error?) -> Void in
            guard let response = task.response else {
                onEvent(StorageEvent.failed(StoragePutError.unknown("Missing HTTP Status", "")))
                return
            }

            guard response.statusCode == 200 else {
                onEvent(StorageEvent.failed(StoragePutError.httpStatusError(
                    "status code \(response.statusCode)", "Check the status code")))
                return
            }

            guard error == nil else {
                let error = error! as NSError
                onEvent(StorageEvent.failed(StoragePutError.unknown("Error with code: \(error.code) ", "")))
                return
            }

            onEvent(StorageEvent.completed(StoragePutResult(key: key)))
        }

        let onTaskCreatedHandler = { (task: AWSTask<AWSS3TransferUtilityUploadTask>) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StoragePutError.unknown(error.localizedDescription, "test")))
            } else if let uploadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(uploadTask)))
            } else {
                onEvent(StorageEvent.failed(StoragePutError.unknown("Failed to ", "")))
            }

            return nil
        }

        // TODO: implementation details MultiPart Upload
        if let fileURL = fileURL {
//            transferUtility.uploadUsingMultiPart(fileURL: fileURL,
//                                                 bucket: bucket,
//                                                 key: serviceKey,
//                                                 contentType: contentType ?? "application/octet-stream",
//                                                 expression: uploadExpression,
//                                                 completionHandler: onCompletedHandler)
        } else if let data = data {
            transferUtility.uploadData(data: data,
                                       bucket: bucket,
                                       key: serviceKey,
                                       contentType: contentType ?? "application/octet-stream",
                                       expression: uploadExpression,
                                       completionHandler: onCompletedHandler).continueWith(block: onTaskCreatedHandler)
        } else {
            onEvent(StorageEvent.failed(StoragePutError.unknown("no file or data", "")))
        }
    }
}
