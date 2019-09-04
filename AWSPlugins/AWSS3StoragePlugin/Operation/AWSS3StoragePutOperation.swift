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

public class AWSS3StoragePutOperation: AmplifyOperation<Progress, StoragePutResult, StoragePutError>,
    StoragePutOperation {

    let request: AWSS3StoragePutRequest
    let service: AWSS3StorageServiceBehaviour
    let mobileClient: AWSMobileClientBehavior
    let onEvent: ((AsyncEvent<Progress, StoragePutResult, StoragePutError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StoragePutRequest,
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
        storageOperationReference?.pause()
    }

    public func resume() {
        storageOperationReference?.resume()
    }

    override public func cancel() {
        storageOperationReference?.cancel()
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        let serviceOnEventBlock = {
            (event: StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void in
            switch event {
            case .initiated(let reference):
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
                let error = StoragePutError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            } else if let identity = task.result {
                self.service.execute(self.request, identity: identity as String, onEvent: serviceOnEventBlock)
            } else {
                let error = StoragePutError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            }

            return nil
        }

        mobileClient.getIdentityId().continueWith(block: getIdentityContinuationBlock)
    }

    private func sendProgressAsyncEvent(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func sendSuccessAsyncEvent(_ result: StoragePutResult) {
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func sendFailedAsyncEvent(_ error: StoragePutError) {
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
