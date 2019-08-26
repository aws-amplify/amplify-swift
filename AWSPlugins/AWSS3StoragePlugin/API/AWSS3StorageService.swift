//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

// Takes a request object and executes using one of its dependencies.
//
public class AWSS3StorageService: AWSS3StorageServiceBehaviour {
    var transferUtility: AWSS3TransferUtilityBehavior
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior
    var s3: AWSS3Behavior
    
    init(transferUtility: AWSS3TransferUtilityBehavior,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         s3: AWSS3Behavior) {
        self.transferUtility = transferUtility
        self.preSignedURLBuilder = preSignedURLBuilder
        self.s3 = s3
    }
    
    init(region: String, poolId: String, credentialsProviderRegion: String, key: String) {
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: credentialsProviderRegion.aws_regionTypeValue(), identityPoolId: poolId)
        let serviceConfiguration: AWSServiceConfiguration = AWSServiceConfiguration(region: region.aws_regionTypeValue(), credentialsProvider: credentialProvider)
        
        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: key)
        AWSS3PreSignedURLBuilder.register(with: serviceConfiguration, forKey: key)
        AWSS3.register(with: serviceConfiguration, forKey: key)
        
        self.transferUtility = AWSS3TransferUtilityImpl(AWSS3TransferUtility.s3TransferUtility(forKey: key)!)
        self.preSignedURLBuilder = AWSS3PreSignedURLBuilderImpl(AWSS3PreSignedURLBuilder.s3PreSignedURLBuilder(forKey: key))
        self.s3 = AWSS3Impl(AWSS3.s3(forKey: key))
    }
    
    public func execute(_ request: AWSS3StorageGetRequest, onEvent: @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }
        
        let completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, location, data, error ) in
            if let HTTPResponse = task.response {
                print("Status: \(HTTPResponse)")
                // TODO: handle non success response
                // check if non success and thenr eturn error
            }
            if let error = error {
                onEvent(StorageEvent.failed(StorageGetError(errorDescription: "test", recoverySuggestion: "test")))
            } else if let data = data {
                onEvent(StorageEvent.completed(StorageGetResult(data: data)))
            } else {
                // Fail hard.
                
            }
        }
        
        let continuationBlock = { (task: AWSTask<AWSS3TransferUtilityDownloadTask>) -> Any? in
            
            if let error = task.error {
                onEvent(StorageEvent.failed(StorageGetError(errorDescription: "test", recoverySuggestion: "test")))
            } else if let downloadTask = task.result {
                onEvent(StorageEvent.initiated(StorageOperationReference(downloadTask)))
            } else {
                // Fail hard
                onEvent(StorageEvent.failed(StorageGetError(errorDescription: "test", recoverySuggestion: "test")))
            }
            
            return nil
        }
        
        if let fileURL = request.fileURL {
            let task = transferUtility.download(to: fileURL, bucket: request.bucket, key: request.key, expression: expression, completionHandler: completionHandler)
            task.continueWith(block: continuationBlock)
        } else {
            let task = transferUtility.downloadData(
                fromBucket: request.bucket,
                key: request.key,
                expression: expression,
                completionHandler: completionHandler);
            task.continueWith(block: continuationBlock)
        }
    }
    
    public func execute(_ request: AWSS3StorageGetUrlRequest, onEvent: @escaping (StorageEvent<Void, Void, StorageGetUrlResult, StorageGetUrlError>) -> Void) {
        print("Executing AWSS3StorageGetUrlOperation")
        
        let getPresignedURLRequest = AWSS3GetPreSignedURLRequest()
        getPresignedURLRequest.bucket = request.bucket
        getPresignedURLRequest.key = request.key
        getPresignedURLRequest.httpMethod = AWSHTTPMethod.GET
        getPresignedURLRequest.expires = NSDate(timeIntervalSinceNow: 18000) as Date
        
        self.preSignedURLBuilder.getPreSignedURL(getPresignedURLRequest).continueWith { (task) -> Any? in
            if let error = task.error {
                print("Error: \(error.localizedDescription)")
            }
            
            if let result = task.result {
                onEvent(StorageEvent.completed(StorageGetUrlResult(url: result)))
            }
            
            return nil
        }
        onEvent(StorageEvent.initiated(()))
    }
    
    public func execute(_ request: AWSS3StoragePutRequest, onEvent: @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void) {
        let uploadExpression = AWSS3TransferUtilityUploadExpression()
        uploadExpression.progressBlock = {(task, progress) in
            onEvent(StorageEvent.inProcess(progress))
        }
        
        let completionHandler = { (task: AWSS3TransferUtilityUploadTask, error: Error?) -> Void in
            if let HTTPResponse = task.response {
                print("Status: \(HTTPResponse)")
                // TODO: if error, dispatch error event with payload  (task.error)
                // TODO: Hub.dispatch completion event with payload (Success)
                // TODO: self.emitSuccess/emitError
                
            }
            if let error = error {
                print("Failed with error: \(error)")
            } else {
                onEvent(StorageEvent.completed(StoragePutResult(key: request.key)))
            }
        }
        
        
        self.transferUtility.uploadData(
            request.data!,
            bucket: request.bucket,
            key: request.key,
            contentType: "application/octet-stream", // contentType or "binary/octet-stream
            expression: uploadExpression,
            completionHandler: completionHandler).continueWith {(task) -> AnyObject? in
                // TODO: emit error event if any
                if let uploadTask = task.result {
                    onEvent(StorageEvent.initiated(StorageOperationReference(uploadTask)))
                }
                return nil
        }
    }
    
    
    // TODO: batch operation until all results have been gathered.
    public func execute(_ request: AWSS3StorageListRequest, onEvent: @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void) {

        let request: AWSS3ListObjectsV2Request = AWSS3ListObjectsV2Request()
        request.bucket = "swiftstoragesample1fd7e03cf4804cdaac1f0d548fbe3aa0-devo"
        if let path = request.prefix {
            request.prefix = path
        }
        self.s3.listObjectsV2(request).continueWith { (task) -> Any? in
            
            if let error = task.error {
                print("error" + error.localizedDescription)
                // return promise that failed.
            }
            
            if let results = task.result {
                if let contents = results.contents {
                    var list: [String] = Array()
                    for s3Key in contents {
                        list.append(s3Key.key!)
                    }
                    let result = StorageListResult(list: list)
                    onEvent(StorageEvent.completed(StorageListResult(list: list)))
                }
            }
            
            return nil
        }
        onEvent(StorageEvent.initiated(()))
    }
    
    public func execute(_ request: AWSS3StorageRemoveRequest, onEvent: @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void) {
        let deleteObjectRequest : AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest.bucket = request.bucket
        deleteObjectRequest.key = request.key
        
        self.s3.deleteObject(deleteObjectRequest).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error" + error.localizedDescription)
                // if there are errors, dispatch the event to the Hub. developers can subscribe to thre Hub for some of these events.
                // then return the Promise object with failures.
            } else {
                onEvent(StorageEvent.completed(StorageRemoveResult(key: request.key)))
            }
            return nil
        }
        
        onEvent(StorageEvent.initiated(()))
    }
}
