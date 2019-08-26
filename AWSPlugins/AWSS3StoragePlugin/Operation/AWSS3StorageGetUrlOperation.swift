//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageGetUrlOperation: AmplifyOperation<Void, StorageGetUrlResult, StorageGetUrlError>, StorageGetUrlOperation {
    
    let request: AWSS3StorageGetUrlRequest
    let service: AWSS3StorageServiceBehaviour
    let onComplete: ((CompletionEvent<StorageGetUrlResult, StorageGetUrlError>) -> Void)?
    
    var storageOperationReference: StorageOperationReference?
    
    init(_ request: AWSS3StorageGetUrlRequest,
         service: AWSS3StorageServiceBehaviour,
         onComplete: ((CompletionEvent<CompletedType, ErrorType>) -> Void)?) {
        
        self.request = request
        self.service = service
        self.onComplete = onComplete
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        self.storageOperationReference?.cancel()
        cancel()
    }
 
    override public func main() {
        if (isCancelled) {
            return
        }
        
        self.service.execute(self.request, onEvent: { (event) in
            switch(event) {
            case .initiated:
                break
            case .inProcess(let progress):
                print("Amplify.Hub.dispatch(to: .storage, payload: AsyncEvent(AsyncEvent.inProcess(progress)))")
                break
            case .completed(let result):
                print(result)
                self.onComplete?(CompletionEvent.completed(result))
                self.finish()
                break
            case .failed(let error):
                self.onComplete?(CompletionEvent.failed(error))
                self.finish()
                break
            }
        })
    }
}
