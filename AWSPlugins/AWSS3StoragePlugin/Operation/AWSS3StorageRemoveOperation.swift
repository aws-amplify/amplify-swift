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

public class AWSS3StorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>,
    StorageRemoveOperation {

    let request: AWSS3StorageRemoveRequest
    let service: AWSS3StorageServiceBehaviour
    let mobileClient: AWSMobileClientBehavior
    let onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?

    init(_ request: AWSS3StorageRemoveRequest,
         service: AWSS3StorageServiceBehaviour,
         mobileClient: AWSMobileClientBehavior,
         onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?) {

        self.request = request
        self.service = service
        self.mobileClient = mobileClient
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            self.sendFailedAsyncEvent(error)
            finish()
            return
        }

        let serviceOnEventBlock = { (event: StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void in
            switch event {
            case .initiated:
                break
            case .inProcess:
                break
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
                let error = StorageRemoveError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            } else if let identity = task.result {
                self.service.execute(self.request, identity: identity as String, onEvent: serviceOnEventBlock)
            } else {
                let error = StorageRemoveError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            }

            return nil
        }

        mobileClient.getIdentityId().continueWith(block: getIdentityContinuationBlock)
    }

    private func sendSuccessAsyncEvent(_ result: StorageRemoveResult) {
        let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func sendFailedAsyncEvent(_ error: StorageRemoveError) {
        let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
