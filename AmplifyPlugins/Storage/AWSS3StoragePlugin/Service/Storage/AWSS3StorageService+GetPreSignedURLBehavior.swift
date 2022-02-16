//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import AWSS3
import Amplify

public typealias GetURLCompletedHandler = (AWSTask<NSURL>) -> Any?

extension AWSS3StorageService {
    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {

        let getPresignedURLRequest = AWSS3StorageService.makeAWSS3GetPreSignedURLRequest(bucket: bucket,
                                                                                         key: serviceKey,
                                                                                         expires: expires)

        let getPresignedURLCompletedHandler =
            AWSS3StorageService.makeGetPreSignedURLCompletedHandler(onEvent: onEvent)

        preSignedURLBuilder.getPreSignedURL(getPresignedURLRequest)
            .continueWith(block: getPresignedURLCompletedHandler)
    }

    private static func makeAWSS3GetPreSignedURLRequest(bucket: String,
                                                        key: String,
                                                        expires: Int) -> AWSS3GetPreSignedURLRequest {
        let request = AWSS3GetPreSignedURLRequest()
        request.bucket = bucket
        request.key = key
        request.httpMethod = AWSHTTPMethod.GET
        let timeIntervalSinceNow = Double(expires)
        request.expires = NSDate(timeIntervalSinceNow: timeIntervalSinceNow) as Date

        return request
    }

    private static func makeGetPreSignedURLCompletedHandler(
        onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) -> GetURLCompletedHandler {

        let block: GetURLCompletedHandler = { (task: AWSTask<NSURL>) -> Any? in
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

            onEvent(StorageEvent.completed(result as URL))

            return nil
        }

        return block
    }
}
 */
