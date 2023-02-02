//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

typealias ListCompletedHandler = (AWSTask<AWSS3ListObjectsV2Output>) -> Any?

extension AWSS3StorageService {
    func list(prefix: String, path: String?, onEvent: @escaping StorageServiceListEventHandler) {
        // swiftlint:disable:next todo
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
        onEvent: @escaping StorageServiceListEventHandler, prefix: String) -> ListCompletedHandler {

        let block: ListCompletedHandler = { (task: AWSTask<AWSS3ListObjectsV2Output>) -> Any? in
            guard task.error == nil else {
                let error = task.error! as NSError
                let storageError = StorageErrorHelper.mapServiceError(error)
                onEvent(StorageEvent.failed(storageError))
                return nil
            }

            guard let result = task.result else {
                onEvent(StorageEvent.failed(StorageError.unknown("Missing result data")))
                return nil
            }

            var items = [StorageListResult.Item]()

            guard let contents = result.contents else {
                onEvent(StorageEvent.completed(StorageListResult(items: items)))
                return nil
            }

            for content in contents {
                guard let fullKey = content.key else {
                    onEvent(StorageEvent.failed(StorageError.unknown("Missing key in response")))
                    return nil
                }

                let resultKey = String(fullKey.dropFirst(prefix.count))

                guard let eTag = content.eTag else {
                    onEvent(StorageEvent.failed(StorageError.unknown("Missing eTag in response")))
                    return nil
                }

                guard let lastModified = content.lastModified else {
                    onEvent(StorageEvent.failed(StorageError.unknown("Missing lastModified in response")))
                    return nil
                }

                guard let size = content.size else {
                    onEvent(StorageEvent.failed(StorageError.unknown("Missing size in response")))
                    return nil
                }

                items.append(StorageListResult.Item(key: resultKey,
                                                    size: size.intValue,
                                                    eTag: String(eTag.dropFirst().dropLast()),
                                                    lastModified: lastModified))
            }

            onEvent(StorageEvent.completed(StorageListResult(items: items)))

            return nil
        }

        return block
    }

}
