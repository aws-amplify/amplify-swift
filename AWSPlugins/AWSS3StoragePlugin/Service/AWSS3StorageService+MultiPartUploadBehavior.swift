//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

public typealias MultiPartUploadTaskCreatedHandler = (AWSTask<AWSS3TransferUtilityMultiPartUploadTask>) -> Any?

extension AWSS3StorageService {

    public func multiPartUpload(serviceKey: String,
                                key: String,
                                uploadSource: UploadSource,
                                contentType: String?,
                                metadata: [String: String]?,
                                onEvent: @escaping StorageMultiPartUploadOnEventHandler) {

        let multiPartUploadTaskCreatedHandler =
            AWSS3StorageService.makeMultiPartUploadTaskCreatedHandler(onEvent: onEvent)
        let expression = AWSS3TransferUtilityMultiPartUploadExpression()
        expression.progressBlock = AWSS3StorageService.makeOnMultiPartUploadProgressHandler(onEvent: onEvent)
        if let metadata = metadata {
            for (key, value) in metadata {
                expression.setValue(value, forRequestHeader: key)
            }
        }
        
        let onMultiPartUploadCompletedHandler =
            AWSS3StorageService.makeMultiPartUploadCompletedHandler(onEvent: onEvent, key: key)

        switch uploadSource {
        case .data(let data):
            transferUtility.uploadUsingMultiPart(data: data,
                                                 bucket: bucket,
                                                 key: serviceKey,
                                                 contentType: contentType ?? "application/octet-stream",
                                                 expression: expression,
                                                 completionHandler: onMultiPartUploadCompletedHandler)
                .continueWith(block: multiPartUploadTaskCreatedHandler)
        case .file(let fileURL):
            transferUtility.uploadUsingMultiPart(fileURL: fileURL,
                                                 bucket: bucket,
                                                 key: serviceKey,
                                                 contentType: contentType ?? "application/octet-stream",
                                                 expression: expression,
                                                 completionHandler: onMultiPartUploadCompletedHandler)
                .continueWith(block: multiPartUploadTaskCreatedHandler)
        }
    }

    private static func makeMultiPartUploadTaskCreatedHandler(
        onEvent: @escaping StorageMultiPartUploadOnEventHandler) -> MultiPartUploadTaskCreatedHandler {

        let block: MultiPartUploadTaskCreatedHandler = {
            (task: AWSTask<AWSS3TransferUtilityMultiPartUploadTask>) -> Any? in

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

    private static func makeOnMultiPartUploadProgressHandler(
        onEvent: @escaping StorageMultiPartUploadOnEventHandler) -> AWSS3TransferUtilityMultiPartProgressBlock {
        let block: AWSS3TransferUtilityMultiPartProgressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        return block
    }

    private static func makeMultiPartUploadCompletedHandler(
        onEvent: @escaping StorageMultiPartUploadOnEventHandler,
        key: String) -> AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock {

        let block: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock = { (task, error ) -> Void in
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
