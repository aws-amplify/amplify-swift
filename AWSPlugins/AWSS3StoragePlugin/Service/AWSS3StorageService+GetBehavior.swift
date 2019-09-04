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
    public func execute(_ request: AWSS3StorageGetRequest, identity: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {

        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        let completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, location, data, error ) in
            if let HTTPResponse = task.response {
                if HTTPResponse.statusCode != 200 {
                    onEvent(StorageEvent.failed(StorageGetError.httpStatusError(
                        "status code \(HTTPResponse.statusCode)", "Check the status code")))
                    return
                }
            }

            if let error = error {
                //print(error)
                //let tError = AWSS3TransferUtilityErrorType.init(rawValue: error.code)
                //TODO: how to extract code, message, out?
                //                if case let error as NSError {
                //                    error.userInfo
                //                }
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "TODO")))
            } else if let data = data {
                onEvent(StorageEvent.completed(StorageGetResult(data: data)))
            } else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("No completionBlock data", "")))
            }
        }

        let continuationBlock = { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "test")))
            } else if let downloadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(downloadTask)))
            } else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("No ContinuationBlock data", "")))
            }

            return nil
        }

        if let fileURL = request.fileURL {
            let task = transferUtility.download(to: fileURL,
                                                bucket: request.bucket,
                                                key: request.getFinalKey(identity: identity),
                                                expression: expression,
                                                completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        } else {
            let task = transferUtility.downloadData(
                fromBucket: request.bucket,
                key: request.getFinalKey(identity: identity),
                expression: expression,
                completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        }
    }
}
