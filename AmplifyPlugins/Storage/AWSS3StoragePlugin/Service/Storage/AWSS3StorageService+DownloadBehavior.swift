//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

public typealias DownloadTaskCreatedHandler = (AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any?

extension AWSS3StorageService {
    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageServiceDownloadEventHandler) {

        let downloadTaskCreatedHandler = AWSS3StorageService.makeDownloadTaskCreatedHandler(onEvent: onEvent)
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = AWSS3StorageService.makeOnDownloadProgressHandler(onEvent: onEvent)
        let onDownloadCompletedHandler = AWSS3StorageService.makeDownloadCompletedHandler(onEvent: onEvent,
                                                                                          serviceKey: serviceKey)

        if let fileURL = fileURL {
            transferUtility.download(to: fileURL,
                                     bucket: bucket,
                                     key: serviceKey,
                                     expression: expression,
                                     completionHandler: onDownloadCompletedHandler)
                .continueWith(block: downloadTaskCreatedHandler)
        } else {
            transferUtility.downloadData(fromBucket: bucket,
                                         key: serviceKey,
                                         expression: expression,
                                         completionHandler: onDownloadCompletedHandler)
                .continueWith(block: downloadTaskCreatedHandler)

        }
    }

    private static func makeDownloadTaskCreatedHandler(
        onEvent: @escaping StorageServiceDownloadEventHandler) -> DownloadTaskCreatedHandler {

        let block: DownloadTaskCreatedHandler = { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let storageError = StorageErrorHelper.mapTransferUtilityError(error)
                onEvent(StorageEvent.failed(storageError))

                return nil
            }

            guard let downloadTask = task.result else {
                onEvent(StorageEvent.failed(StorageError.unknown("Download started but missing task")))
                return nil
            }

            onEvent(StorageEvent.initiated(StorageTaskReference(downloadTask)))
            return nil
        }

        return block
    }

    private static func makeOnDownloadProgressHandler(
        onEvent: @escaping StorageServiceDownloadEventHandler) -> AWSS3TransferUtilityProgressBlock {

        let block: AWSS3TransferUtilityProgressBlock = {task, progress in
            onEvent(StorageEvent.inProcess(progress))
        }

        return block
    }

    private static func makeDownloadCompletedHandler(
        onEvent: @escaping StorageServiceDownloadEventHandler,
        serviceKey: String) -> AWSS3TransferUtilityDownloadCompletionHandlerBlock {

        let block: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { task, location, data, error in
            guard let response = task.response else {
                onEvent(StorageEvent.failed(StorageError.unknown("Missing HTTP Response")))
                return
            }

            let storageError = StorageErrorHelper.mapHttpResponseCode(statusCode: response.statusCode,
                                                                      serviceKey: serviceKey)
            guard storageError == nil else {
                onEvent(StorageEvent.failed(storageError!))
                return
            }

            guard error == nil else {
                let error = error! as NSError
                let storageError = StorageErrorHelper.mapTransferUtilityError(error)
                onEvent(StorageEvent.failed(storageError))
                return
            }

            onEvent(StorageEvent.completed(data))
        }

        return block
    }
}
