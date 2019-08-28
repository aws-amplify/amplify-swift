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

    override public func main() {
        self.service.execute(self.request, onEvent: { (event) in
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
