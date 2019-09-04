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
    public func execute(_ request: AWSS3StorageRemoveRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void) {

        let deleteObjectRequest: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest.bucket = request.bucket
        deleteObjectRequest.key = request.getFinalKey(identity: identity)

        awsS3.deleteObject(deleteObjectRequest).continueWith { (task) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageRemoveError.unknown(error.localizedDescription, "TODO")))
            } else {
                onEvent(StorageEvent.completed(StorageRemoveResult(key: request.key)))
            }
            return nil
        }

        onEvent(StorageEvent.initiated(()))
    }
}
