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

public class AWSS3StorageListOperation: AmplifyOperation<Void, StorageListResult, StorageListError>,
    StorageListOperation {

    let request: AWSS3StorageListRequest
    let service: AWSS3StorageServiceBehaviour
    let mobileClient: AWSMobileClientBehavior
    let onEvent: ((AsyncEvent<Void, StorageListResult, StorageListError>) -> Void)?

    init(_ request: AWSS3StorageListRequest,
         service: AWSS3StorageServiceBehaviour,
         mobileClient: AWSMobileClientBehavior,
         onEvent: ((AsyncEvent<Void, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
        self.onEvent = onEvent
        self.mobileClient = mobileClient
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            sendFailedAsyncEvent(error)
            finish()
            return
        }

        let serviceOnEventBlock = { (event: StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void in
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
                let error = StorageListError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            } else if let identity = task.result {
                self.service.execute(self.request, identity: identity as String, onEvent: serviceOnEventBlock)
            } else {
                let error = StorageListError.unknown("No Identitiy", "no identity!")
                self.sendFailedAsyncEvent(error)
                self.finish()
            }

            return nil
        }

        mobileClient.getIdentityId().continueWith(block: getIdentityContinuationBlock)
    }

    private func sendSuccessAsyncEvent(_ result: StorageListResult) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func sendFailedAsyncEvent(_ error: StorageListError) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
