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
    public func list(bucket: String, prefix: String, onEvent: @escaping StorageListOnEventHandler) {
        let request = AWSS3StorageService.makeListObjectsV2Request(bucket: bucket, prefix: prefix)

        // TODO: implementation details - use request.options.limit.
        // listObjectsV2Request.maxKeys ?
        // Figure out if we need ay batching logic
        awsS3.listObjectsV2(request).continueWith { (task) -> Any? in
            guard task.error == nil else {
                let error = task.error!
                onEvent(StorageEvent.failed(StorageListError.unknown(error.localizedDescription, "TODO")))
                return nil
            }

            guard let result = task.result else {
                onEvent(StorageEvent.failed(StorageListError.unknown("no error or result", "TODO")))
                return nil
            }

            var list: [String] = Array()
            if let contents = result.contents {
                for s3Key in contents {
                    list.append(s3Key.key!)
                }
            }

            onEvent(StorageEvent.completed(StorageListResult(keys: list)))

            return nil
        }
    }

    private static func makeListObjectsV2Request(bucket: String,
                                                 prefix: String) -> AWSS3ListObjectsV2Request {
        let request: AWSS3ListObjectsV2Request = AWSS3ListObjectsV2Request()
        request.bucket = bucket
        request.prefix = prefix 

        return request
    }


}
