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
    let onComplete: ((CompletionEvent<StorageListResult, StorageListError>) -> Void)?

    init(_ request: AWSS3StorageListRequest,
         service: AWSS3StorageServiceBehaviour,
         onComplete: ((CompletionEvent<CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.service = service
        self.onComplete = onComplete
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
                self.dispatch(event: AsyncEvent.inProcess(progress))
            case .completed(let result):
                self.dispatch(event: AsyncEvent.completed(result))
                self.onComplete?(CompletionEvent.completed(result))
                self.finish()
            case .failed(let error):
                self.dispatch(event: AsyncEvent.failed(error))
                self.onComplete?(CompletionEvent.failed(error))
                self.finish()
            }
        })
    }
}
