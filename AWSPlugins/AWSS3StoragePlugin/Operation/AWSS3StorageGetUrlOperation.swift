//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageGetUrlOperation: AmplifyOperation<Void, StorageGetUrlResult, StorageGetUrlError>,
    StorageGetUrlOperation {

    let request: AWSS3StorageGetUrlRequest
    let service: AWSS3StorageServiceBehaviour
    let onEvent: ((AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>) -> Void)?

    var error: StorageGetUrlError?
    var identity: String?
    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StorageGetUrlRequest,
         service: AWSS3StorageServiceBehaviour,
         onEvent: ((AsyncEvent<Void, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        self.storageOperationReference?.cancel()
        cancel()
    }

    public func failFast(_ error: StorageGetUrlError) -> StorageGetUrlOperation {
        self.error = error
        start()
        return self
    }

    override public func main() {
        if let error = error {
            let asyncEvent = AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        guard let identity = identity else {
            let asyncEvent = AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>.failed(
                StorageGetUrlError.unknown("Did not pass identity over...", "no identity"))
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        self.service.execute(request, identity: identity, onEvent: { (event) in
            switch event {
            case .initiated:
                break
            case .inProcess(let progress):
                let asyncEvent = AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>.inProcess(progress)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
            case .completed(let result):
                let asyncEvent = AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>.completed(result)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            case .failed(let error):
                let asyncEvent = AsyncEvent<Void, StorageGetUrlResult, StorageGetUrlError>.failed(error)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            }
        })
    }
}
