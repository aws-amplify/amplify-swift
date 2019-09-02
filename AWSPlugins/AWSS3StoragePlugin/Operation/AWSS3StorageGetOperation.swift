//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>,
    StorageGetOperation {

    let request: AWSS3StorageGetRequest
    let service: AWSS3StorageServiceBehaviour
    let onEvent: ((AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void)?

    var error: StorageGetError?
    var identity: String?
    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StorageGetRequest,
         service: AWSS3StorageServiceBehaviour,
         onEvent: ((AsyncEvent<Progress, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    public func pause() {
        self.storageOperationReference?.pause()
    }

    public func resume() {
        self.storageOperationReference?.resume()
    }

    override public func cancel() {
        self.storageOperationReference?.cancel()
        cancel()
    }

    public func failFast(_ error: StorageGetError) -> StorageGetOperation {
        self.error = error
        start()
        return self
    }

    override public func main() {
        if let error = error {
            let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        guard let identity = identity else {
            let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.failed(
                StorageGetError.unknown("Did not pass identity over...", "no identity"))
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        service.execute(request, identity: identity, onEvent: { event in
            switch event {
            case .initiated(let reference):
                self.storageOperationReference = reference
            case .inProcess(let progress):
                let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.inProcess(progress)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
            case .completed(let result):
                let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.completed(result)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            case .failed(let error):
                let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.failed(error)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            }
        })
    }
}
