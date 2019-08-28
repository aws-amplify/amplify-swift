//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StoragePutOperation: AmplifyOperation<Progress, StoragePutResult, StoragePutError>,
    StoragePutOperation {

    let request: AWSS3StoragePutRequest
    let service: AWSS3StorageServiceBehaviour
    let onEvent: ((AsyncEvent<Progress, StoragePutResult, StoragePutError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StoragePutRequest,
         service: AWSS3StorageServiceBehaviour,
         onEvent: ((AsyncEvent<Progress, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
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
        self.service.execute(self.request, onEvent: { (event) in
            switch event {
            case .initiated(let reference):
                self.storageOperationReference = reference
            case .inProcess(let progress):
                let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.inProcess(progress)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
            case .completed(let result):
                let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.completed(result)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            case .failed(let error):
                let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.failed(error)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            }
        })
    }
}
