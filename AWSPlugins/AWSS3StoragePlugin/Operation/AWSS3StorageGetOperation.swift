//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3
import AWSMobileClient

public class AWSS3StorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>,
    StorageGetOperation {

    let request: AWSS3StorageGetRequest
    let service: AWSS3StorageServiceBehaviour
    let mobileClient: AWSMobileClientBehavior
    let onEvent: ((AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StorageGetRequest,
         service: AWSS3StorageServiceBehaviour,
         mobileClient: AWSMobileClientBehavior,
         onEvent: ((AsyncEvent<Progress, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
        self.mobileClient = mobileClient
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    public func pause() {
        self.storageOperationReference?.pause()
    }

    public func resume() {
        self.storageOperationReference?.resume()
    }

    // TODO: everything has to be locked down
    override public func cancel() {
        self.storageOperationReference?.cancel()
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            sendFailedAsyncEvent(error)
            finish()
            return
        }

        let serviceOnEventBlock = {
            (event: StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void in
            switch event {
            case .initiated(let reference):
                // check if cancelled, then cancel using reference.
                self.storageOperationReference = reference
            case .inProcess(let progress):
                self.sendProgressAsyncEvent(progress)
            case .completed(let result):
                self.sendSuccessAsyncEvent(result)
                self.finish()
            case .failed(let error):
                self.sendFailedAsyncEvent(error)
                self.finish()
            }
        }

        let getIdentityContinuationBlock = { (task: AWSTask<NSString>) -> Any? in
            if let error = task.error as? AWSMobileClientError {
                // TODO MAP to error
                let error = StorageGetError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            } else if let identity = task.result {
                self.service.execute(self.request, identity: identity as String, onEvent: serviceOnEventBlock)
            } else {
                let error = StorageGetError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            }

            return nil
        }

        mobileClient.getIdentityId().continueWith(block: getIdentityContinuationBlock)
    }

    private func sendProgressAsyncEvent(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func sendSuccessAsyncEvent(_ result: StorageGetResult) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func sendFailedAsyncEvent(_ error: StorageGetError) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
