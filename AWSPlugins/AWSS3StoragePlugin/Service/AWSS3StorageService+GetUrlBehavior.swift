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
    public func execute(_ request: AWSS3StorageGetUrlRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageGetUrlResult, StorageGetUrlError>) -> Void) {
        onEvent(StorageEvent.initiated(()))

        let getPresignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPresignedURLRequest.bucket = request.bucket
        getPresignedURLRequest.key = request.getFinalKey(identity: identity)
        getPresignedURLRequest.httpMethod = AWSHTTPMethod.GET
        getPresignedURLRequest.expires = NSDate(timeIntervalSinceNow: 18000) as Date

        self.preSignedURLBuilder.getPreSignedURL(getPresignedURLRequest).continueWith { (task) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageGetUrlError.unknown(error.localizedDescription, "TODO")))
            } else if let result = task.result {
                onEvent(StorageEvent.completed(StorageGetUrlResult(url: result as URL)))
            } else {
                onEvent(StorageEvent.failed(StorageGetUrlError.unknown("No PresignedURL continueWith data", "")))
            }

            return nil
        }
    }
}
