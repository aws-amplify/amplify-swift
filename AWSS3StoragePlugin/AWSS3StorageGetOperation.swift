//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>, StorageGetOperation {
    
    var key: String
    
    var refGetTask: AWSS3TransferUtilityDownloadTask?
    var onEvent: ((AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void)?
    init(key: String) {
        self.key = key
        super.init(categoryType: .storage)
    }
    
    // implements Resumable
    public func pause() {
        self.refGetTask?.suspend()
    }
    
    // implements Resumbable
    public func resume() {
        self.refGetTask?.resume()
    }
    
    // override AmplifyOperation : Cancellable
    override public func cancel() {
        self.refGetTask?.cancel()
        cancel()
    }
    
    func emitEvent(progress: Progress) {
        self.onEvent?(AsyncEvent.inProcess(progress))
    }
    
    func emitSuccess(data: Data) {
        let result = StorageGetResult(data: data)
        self.onEvent?(AsyncEvent.completed(result))
    }
    
    override public func main() {
        print("Executing AWSS3StorageGetOperation")
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: "AWSS3StoragePlugin")
        let downloadExpression = AWSS3TransferUtilityDownloadExpression()
        downloadExpression.progressBlock = {(task, progress) in
            print("got progress")
            self.emitEvent(progress: progress)
        }
        
        let downloadCompletionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { (task, location, data, error ) in
            print("completion handler called")
            if let HTTPResponse = task.response {
                print("Status: \(HTTPResponse)")
            }
            print("data : \(data!)")
            if let data =  data {
                self.emitSuccess(data: data)
            }
            if let error = error {
                print("Error \(error)")
            }
        }
        
        if (isCancelled) {
            return
        }
        
        print("downloading for key \(key)")
        transferUtility?.downloadData(
            fromBucket: "swiftstoragesample1fd7e03cf4804cdaac1f0d548fbe3aa0-devo", // TODO: replace this call with the one that uses the internally configured bucket.
            key: key,
            expression: downloadExpression,
            completionHandler: downloadCompletionHandler).continueWith(block: { (task) -> AnyObject? in
                print("contineWith")
                if let error = task.error {
                    print("Error: \(error.localizedDescription)");
//                    DispatchQueue.main.async(execute: {
//                        self.statusLabel.text = "Failed"
//                    })
                    // todo emit failed event
                }
                // emit error event if any
                if let downloadTask = task.result {
                    if (self.isCancelled) {
                        downloadTask.cancel()
                    } else {
                        self.refGetTask = downloadTask
                        self.emitEvent(progress: Progress())
                    }
                }
                
                return nil
            })
    }
    
    // Temporary hack to replace Hub notifications
//    override open func subscribe(_ onEvent: @escaping (AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void) -> Unsubscribe {
//        print("subscribed with event listener")
//        self.onEvent = onEvent
//        return unsubscribe
//    }
    
    func unsubscribe() {
        print("unsubscribing")
        self.onEvent = nil
    }
}
