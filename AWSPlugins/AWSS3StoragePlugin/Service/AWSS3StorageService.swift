//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify
import AWSMobileClient

// AWSS3StorageService executes request against dependencies (TransferUtility, S3, PreSignedURLBuilder, etc)
public class AWSS3StorageService: AWSS3StorageServiceBehaviour {

    private var transferUtility: AWSS3TransferUtilityBehavior!
    private var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    private var awsS3: AWSS3Behavior!

    init(transferUtility: AWSS3TransferUtilityBehavior,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         awsS3: AWSS3Behavior) {
        self.transferUtility = transferUtility
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
    }

    // TODO: use builder pattern to init, 
    init(region: String, key: String) throws {

        let serviceConfigurationOptional = AWSServiceConfiguration(region:
            region.aws_regionTypeValue(), credentialsProvider: AWSMobileClient.sharedInstance())

        guard let serviceConfiguration = serviceConfigurationOptional else {
            throw PluginError.pluginConfigurationError("T##ErrorDescription", "T##RecoverySuggestion")
        }

        // TODO: this is sort of a hack - need to figure out how to deallocate the nsurlsession?
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: key)
        if let transferUtility = transferUtility {
            self.transferUtility = AWSS3TransferUtilityImpl(transferUtility)
        } else {
            AWSS3TransferUtility.register(with: serviceConfiguration, forKey: key)
            self.transferUtility = AWSS3TransferUtilityImpl(AWSS3TransferUtility.s3TransferUtility(forKey: key)!)

        }

        AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: key)
        AWSS3.register(with: serviceConfiguration, forKey: key)

        self.preSignedURLBuilder = AWSS3PreSignedURLBuilderImpl(
            AWSS3PreSignedURLBuilder.s3PreSignedURLBuilder(forKey: key))
        self.awsS3 = AWSS3Impl(AWSS3.s3(forKey: key))
    }

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
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "TODO")))
            } else if let data = data {
                onEvent(StorageEvent.completed(StorageGetResult(data: data)))
            } else {
                // Fail hard.

            }
        }

        let continuationBlock = { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageGetError.unknown(error.localizedDescription, "test")))
            } else if let downloadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(downloadTask)))
            } else {
                onEvent(StorageEvent.failed(StorageGetError.unknown("Failed to ", "")))
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

            }

            return nil
        }
    }

    public func execute(_ request: AWSS3StoragePutRequest, identity: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void) {

        let uploadExpression = AWSS3TransferUtilityUploadExpression()
        uploadExpression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }

        let completionHandler = { (task: AWSS3TransferUtilityUploadTask, error: Error?) -> Void in
            if let HTTPResponse = task.response {
                if HTTPResponse.statusCode != 200 {
                    onEvent(StorageEvent.failed(StoragePutError.httpStatusError(
                        "status code \(HTTPResponse.statusCode)", "Check the status code")))
                    return
                }
            }
            if let error = error {
                onEvent(StorageEvent.failed(StoragePutError.unknown(error.localizedDescription, "TODO")))
            } else {
                onEvent(StorageEvent.completed(StoragePutResult(key: request.key)))
            }
        }

        let continuationBlock = { (task: AWSTask<AWSS3TransferUtilityUploadTask>) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StoragePutError.unknown(error.localizedDescription, "test")))
            } else if let uploadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(uploadTask)))
            } else {
                onEvent(StorageEvent.failed(StoragePutError.unknown("Failed to ", "")))
            }

            return nil
        }

        if let fileURL = request.fileURL {
            let task = transferUtility.uploadFile(fileURL,
                                                  bucket: request.bucket,
                                                  key: request.getFinalKey(identity: identity),
                                                  contentType: request.contentType ?? "application/octet-stream",
                                                  expression: uploadExpression,
                                                  completionHandler: completionHandler)

            task.continueWith(block: continuationBlock)
        } else {
            let task = transferUtility.uploadData(
                request.data!,
                bucket: request.bucket,
                key: request.getFinalKey(identity: identity),
                contentType: "application/octet-stream", // contentType or "binary/octet-stream
                expression: uploadExpression,
                completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        }


    }

    // TODO: batch operation until all results have been gathered.
    // list will only list 1000. can we set a limit
    public func execute(_ request: AWSS3StorageListRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void) {
        onEvent(StorageEvent.initiated(()))

        let listObjectsV2Request: AWSS3ListObjectsV2Request = AWSS3ListObjectsV2Request()
        listObjectsV2Request.bucket = request.bucket
        listObjectsV2Request.prefix = request.getFinalPrefix(identity: identity)
        
        awsS3.listObjectsV2(listObjectsV2Request).continueWith { (task) -> Any? in
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageListError.unknown(error.localizedDescription, "TODO")))
            } else if let results = task.result {
                if let contents = results.contents {
                    var list: [String] = Array()
                    for s3Key in contents {
                        list.append(s3Key.key!)
                    }

                    onEvent(StorageEvent.completed(StorageListResult(keys: list)))
                }
            } else {
                onEvent(StorageEvent.failed(StorageListError.unknown("no error or result", "TODO")))
            }

            return nil
        }
    }

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
