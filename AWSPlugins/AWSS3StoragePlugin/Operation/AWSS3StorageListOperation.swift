//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageListOperation: AmplifyOperation<Void, StorageListResult, StorageListError>,
    StorageListOperation {

    let request: AWSS3StorageListRequest
    let service: AWSS3StorageServiceBehaviour
    let onEvent: ((AsyncEvent<Void, StorageListResult, StorageListError>) -> Void)?

    init(_ request: AWSS3StorageListRequest,
         service: AWSS3StorageServiceBehaviour,
         onEvent: ((AsyncEvent<Void, CompletedType, ErrorType>) -> Void)?) {

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
            case .inProcess(let progress):
                let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.inProcess(progress)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
            case .completed(let result):
                let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.completed(result)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            case .failed(let error):
                let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.failed(error)
                self.dispatch(event: asyncEvent)
                self.onEvent?(asyncEvent)
                self.finish()
            }
        })
    }
}
