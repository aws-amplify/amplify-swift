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
    public func execute(_ request: AWSS3StorageListRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void) {
        onEvent(StorageEvent.initiated(()))

        let listObjectsV2Request: AWSS3ListObjectsV2Request = AWSS3ListObjectsV2Request()
        listObjectsV2Request.bucket = request.bucket
        listObjectsV2Request.prefix = request.getFinalPrefix(identity: identity)

        // TODO: implementation details - use request.options.limit.
        // Figure out batching logic
        awsS3.listObjectsV2(listObjectsV2Request).continueWith { (task) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageListError.unknown(error.localizedDescription, "TODO")))
            } else if let results = task.result {
                var list: [String] = Array()
                if let contents = results.contents {
                    for s3Key in contents {
                        list.append(s3Key.key!)
                    }
                }

                onEvent(StorageEvent.completed(StorageListResult(keys: list)))
            } else {
                onEvent(StorageEvent.failed(StorageListError.unknown("no error or result", "TODO")))
            }

            return nil
        }
    }
}
