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
    public func execute(_ request: AWSS3StorageGetRequest, identityId: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key)
        switch request.storageGetDestination {
        case .data:
            download(bucket: request.bucket, serviceKey: serviceKey, fileURL: nil, onEvent: onEvent)
        case .file(let local):
            download(bucket: request.bucket, serviceKey: serviceKey, fileURL: local, onEvent: onEvent)
        case .url(let expires):
            getRemoteURL(bucket: request.bucket, serviceKey: serviceKey, expires: expires, onEvent: onEvent)
        }
    }

    func download(bucket: String, serviceKey: String, fileURL: URL?, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {

        let onTaskCreatedHandler = { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
            guard task.error == nil else {
                let error = task.error!
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "test")))
                return nil
            }

            guard let downloadTask = task.result else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("No ContinuationBlock data", "")))
                return nil
            }

            onEvent(StorageEvent.initiated(StorageOperationReference(downloadTask)))
            return nil
        }

        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        let onCompletedHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, location, data, error ) in
            guard let response = task.response else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("Missing HTTP Status", "")))
                return
            }

            guard response.statusCode == 200 else {
                onEvent(StorageEvent.failed(StorageGetError.httpStatusError(
                    "status code \(response.statusCode)", "Check the status code")))
                return
            }

            guard error == nil else {
                let error = error! as NSError

                onEvent(StorageEvent.failed(StorageGetError.unknown("Error with code: \(error.code) ", "")))
                return
            }

            guard let data = data else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("No completionBlock data", "")))
                return
            }

            onEvent(StorageEvent.completed(StorageGetResult(data: data)))
        }

        if let fileURL = fileURL {
            let task = transferUtility.download(to: fileURL,
                                                bucket: bucket,
                                                key: serviceKey,
                                                expression: expression,
                                                completionHandler: onCompletedHandler)
            task.continueWith(block: onTaskCreatedHandler)
        } else {
            let task = transferUtility.downloadData(
                fromBucket: bucket,
                key: serviceKey,
                expression: expression,
                completionHandler: onCompletedHandler)
            task.continueWith(block: onTaskCreatedHandler)
        }
    }

    func getRemoteURL(bucket: String, serviceKey: String, expires: Int?, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {
        let getPresignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPresignedURLRequest.bucket = bucket
        getPresignedURLRequest.key = serviceKey
        getPresignedURLRequest.httpMethod = AWSHTTPMethod.GET
        var timeIntervalSinceNow: TimeInterval = 18000
        if let expires = expires {
            timeIntervalSinceNow = Double(expires)
        }
        getPresignedURLRequest.expires = NSDate(timeIntervalSinceNow: timeIntervalSinceNow) as Date

        self.preSignedURLBuilder.getPreSignedURL(getPresignedURLRequest).continueWith { (task) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "TODO")))
            } else if let result = task.result {
                onEvent(StorageEvent.completed(StorageGetResult(remote: result as URL)))
            } else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("No PresignedURL continueWith data", "")))
            }

            return nil
        }
    }
}
