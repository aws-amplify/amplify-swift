//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
        let onDownloadCompletedHandler = AWSS3StorageService.makeDownloadCompletedHandler(fileURL: fileURL,
                                                                                          serviceKey: serviceKey,
                                                                                          onEvent: onEvent)

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

        let block: AWSS3TransferUtilityProgressBlock = {_, progress in
            onEvent(StorageEvent.inProcess(progress))
        }

        return block
    }

    private static func makeDownloadCompletedHandler(
        fileURL: URL? = nil,
        serviceKey: String,
        onEvent: @escaping StorageServiceDownloadEventHandler) -> AWSS3TransferUtilityDownloadCompletionHandlerBlock {

        let block: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { task, _, data, error in
            guard let response = task.response else {
                onEvent(StorageEvent.failed(StorageError.unknown("Missing HTTP Response")))
                return
            }

            if let storageError = StorageErrorHelper.mapHttpResponseCode(statusCode: response.statusCode,
                                                                         serviceKey: serviceKey) {
                deleteFileIfKeyNotFound(storageError: storageError, fileURL: fileURL)
                onEvent(StorageEvent.failed(storageError))
                return
            }

            guard error == nil else {
                let error = error! as NSError
                let storageError = StorageErrorHelper.mapTransferUtilityError(error)
                deleteFileIfKeyNotFound(storageError: storageError, fileURL: fileURL)
                onEvent(StorageEvent.failed(storageError))
                return
            }

            onEvent(StorageEvent.completed(data))
        }

        return block
    }

    // TransferUtility saves the error response at the file location when the key cannot be found in S3
    // This is an best-effort attempt to ensure that the file is removed
    private static func deleteFileIfKeyNotFound(storageError: StorageError, fileURL: URL?) {
        if case .keyNotFound = storageError, let fileURL = fileURL {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                Amplify.Logging.error(error: error)
            }
        }
    }
}
