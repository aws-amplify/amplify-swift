//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

public typealias MultiPartUploadTaskCreatedHandler = (AWSTask<AWSS3TransferUtilityMultiPartUploadTask>) -> Any?

extension AWSS3StorageService {

    func multiPartUpload(serviceKey: String,
                         uploadSource: UploadSource,
                         contentType: String?,
                         metadata: [String: String]?,
                         onEvent: @escaping StorageServiceMultiPartUploadEventHandler) {

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
            AWSS3StorageService.makeMultiPartUploadCompletedHandler(onEvent: onEvent)

        switch uploadSource {
        case .data(let data):
            transferUtility.uploadUsingMultiPart(data: data,
                                                 bucket: bucket,
                                                 key: serviceKey,
                                                 contentType: contentType ?? "application/octet-stream",
                                                 expression: expression,
                                                 completionHandler: onMultiPartUploadCompletedHandler)
                .continueWith(block: multiPartUploadTaskCreatedHandler)
        case .local(let fileURL):
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
        onEvent: @escaping StorageServiceMultiPartUploadEventHandler) -> MultiPartUploadTaskCreatedHandler {

        let block: MultiPartUploadTaskCreatedHandler = { (task: AWSTask<AWSS3TransferUtilityMultiPartUploadTask>) -> Any? in // swiftlint:disable:this line_length

            guard task.error == nil else {
                let error = task.error! as NSError
                let storageError = StorageErrorHelper.mapServiceError(error)
                onEvent(StorageEvent.failed(storageError))

                return nil
            }

            guard let uploadTask = task.result else {
                onEvent(StorageEvent.failed(StorageError.unknown("No ContinuationBlock data")))
                return nil
            }

            onEvent(StorageEvent.initiated(StorageTaskReference(uploadTask)))
            return nil
        }

        return block
    }

    private static func makeOnMultiPartUploadProgressHandler(
        onEvent: @escaping StorageServiceMultiPartUploadEventHandler) -> AWSS3TransferUtilityMultiPartProgressBlock {
        let block: AWSS3TransferUtilityMultiPartProgressBlock = {_, progress in
            onEvent(StorageEvent.inProcess(progress))
        }

        return block
    }

    private static func makeMultiPartUploadCompletedHandler(
        onEvent: @escaping StorageServiceMultiPartUploadEventHandler)
        -> AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock {

        let block: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock = { (_, error) -> Void in
            guard error == nil else {
                let error = error! as NSError
                let storageError = StorageErrorHelper.mapTransferUtilityError(error)
                onEvent(StorageEvent.failed(storageError))
                return
            }

            onEvent(StorageEvent.completedVoid)
        }

        return block
    }
}
