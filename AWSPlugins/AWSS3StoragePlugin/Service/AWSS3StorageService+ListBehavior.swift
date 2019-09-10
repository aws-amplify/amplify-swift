//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

typealias ListCompletedHandler = (AWSTask<AWSS3ListObjectsV2Output>) -> Any?

extension AWSS3StorageService {
    public func list(prefix: String, path: String?, onEvent: @escaping StorageListOnEventHandler) {
        // TODO: implementation details - use request.options.limit.
        // listObjectsV2Request.maxKeys ?
        // Figure out if we need ay batching logic

        var finalPrefix = prefix
        if let path = path {
            finalPrefix += path
        }

        let request = AWSS3StorageService.makeListObjectsV2Request(bucket: bucket, finalPrefix: finalPrefix)
        let listCompletedHandler = AWSS3StorageService.makeListCompletedHandler(onEvent: onEvent, prefix: prefix)

        awsS3.listObjectsV2(request).continueWith(block: listCompletedHandler)
    }

    private static func makeListObjectsV2Request(bucket: String,
                                                 finalPrefix: String) -> AWSS3ListObjectsV2Request {
        let request: AWSS3ListObjectsV2Request = AWSS3ListObjectsV2Request()
        request.bucket = bucket
        request.prefix = finalPrefix

        return request
    }

    private static func makeListCompletedHandler(
        onEvent: @escaping StorageListOnEventHandler, prefix: String) -> ListCompletedHandler {

        let block: ListCompletedHandler = { (task: AWSTask<AWSS3ListObjectsV2Output>) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                // default error handling on NSError
                let innerMessage = StorageErrorHelper.getInnerMessage(error)
                let errorDescription = StorageErrorHelper.getErrorDescription(innerMessage: innerMessage)
                var storageListError = StorageListError.unknown(errorDescription, "RecoverMessage")

                // Ensure it is the right domain
                guard error.domain == AWSServiceErrorDomain else {
                    onEvent(StorageEvent.failed(storageListError))
                    return nil
                }

                // Try to get specific erorr
                let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
                guard let errorType = errorTypeOptional else {
                    onEvent(StorageEvent.failed(storageListError))
                    return nil
                }

                // Extract specific error details and map to Amplify error
                let storageListErrorOptional = StorageErrorHelper.map(errorType)

                onEvent(StorageEvent.failed(storageListErrorOptional ?? storageListError))
                return nil
            }

            guard let result = task.result else {
                onEvent(StorageEvent.failed(StorageListError.unknown("no error or result", "TODO")))
                return nil
            }

            var list: [String] = Array()
            if let contents = result.contents {
                for content in contents {
                    if let fullKey = content.key {
                        let resultKey = String(fullKey.dropFirst(prefix.count))
                        list.append(resultKey)
                    }
                }
            }

            onEvent(StorageEvent.completed(StorageListResult(keys: list)))

            return nil
        }

        return block
    }

}
