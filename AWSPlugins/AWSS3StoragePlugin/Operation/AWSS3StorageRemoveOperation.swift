//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>,
    StorageRemoveOperation {

    let request: AWSS3StorageRemoveRequest
    let service: AWSS3StorageServiceBehaviour
    let onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?

    var error: StorageRemoveError?
    var identity: String?

    init(_ request: AWSS3StorageRemoveRequest,
         service: AWSS3StorageServiceBehaviour,
         onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?) {

        self.request = request
        self.service = service
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        cancel()
    }

    public func failFast(_ error: StorageRemoveError) -> StorageRemoveOperation {
        self.error = error
        start()
        return self
    }

    override public func main() {
        if let error = error {
            let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        guard let identity = identity else {
            let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.failed(
                StorageRemoveError.unknown("Did not pass identity over...", "no identity"))
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        self.service.execute(self.request, identity: identity, onEvent: { (event) in
            switch event {
            case .initiated:
                break
            case .inProcess:
                break
            case .completed(let result):
                let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.completed(result)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            case .failed(let error):
                let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.failed(error)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            }
        })
    }
}
