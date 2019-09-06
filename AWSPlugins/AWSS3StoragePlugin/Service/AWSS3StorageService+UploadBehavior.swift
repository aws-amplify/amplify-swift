//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

public typealias UploadTaskCreatedHandler = (AWSTask<AWSS3TransferUtilityUploadTask>) -> Any?

extension AWSS3StorageService {

    public func upload(serviceKey: String,
                       key: String,
                       uploadSource: UploadSource,
                       contentType: String?,
                       onEvent: @escaping StorageUploadOnEventHandler) {

        let uploadTaskCreatedHandler = AWSS3StorageService.makeUploadTaskCreatedHandler(onEvent: onEvent)
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = AWSS3StorageService.makeOnUploadProgressHandler(onEvent: onEvent)
        let onUploadCompletedHandler = AWSS3StorageService.makeUploadCompletedHandler(onEvent: onEvent, key: key)

        switch uploadSource {
        case .data(let data):
            transferUtility.uploadData(data: data,
                                       bucket: bucket,
                                       key: serviceKey,
                                       contentType: contentType ?? "application/octet-stream",
                                       expression: expression,
                                       completionHandler: onUploadCompletedHandler)
                .continueWith(block: uploadTaskCreatedHandler)
        case .file(let fileURL):
            transferUtility.uploadFile(fileURL: fileURL,
                                       bucket: bucket,
                                       key: serviceKey,
                                       contentType: contentType ?? "application/octet-stream",
                                       expression: expression,
                                       completionHandler: onUploadCompletedHandler)
                .continueWith(block: uploadTaskCreatedHandler)
        }
    }

    private static func makeUploadTaskCreatedHandler(
        onEvent: @escaping StorageUploadOnEventHandler) -> UploadTaskCreatedHandler {

        let block: UploadTaskCreatedHandler = { (task: AWSTask<AWSS3TransferUtilityUploadTask>) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let innerMessage = StorageErrorHelper.getInnerMessage(error)
                let errorDescription = StorageErrorHelper.getErrorDescription(innerMessage: innerMessage)
                onEvent(StorageEvent.failed(StoragePutError.unknown(errorDescription, "Recovery Message")))

                return nil
            }

            guard let uploadTask = task.result else {
                onEvent(StorageEvent.failed(StoragePutError.unknown("No ContinuationBlock data", "")))
                return nil
            }

            onEvent(StorageEvent.initiated(StorageOperationReference(uploadTask)))
            return nil
        }

        return block
    }

    private static func makeOnUploadProgressHandler(
        onEvent: @escaping StorageUploadOnEventHandler) -> AWSS3TransferUtilityProgressBlock {
            let block: AWSS3TransferUtilityProgressBlock = {(task, progress) in
                onEvent(StorageEvent.inProcess(progress))
            }

            return block
    }

    private static func makeUploadCompletedHandler(
        onEvent: @escaping StorageUploadOnEventHandler,
        key: String) -> AWSS3TransferUtilityUploadCompletionHandlerBlock {

        let block: AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error ) -> Void in
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

        return block
    }
}
