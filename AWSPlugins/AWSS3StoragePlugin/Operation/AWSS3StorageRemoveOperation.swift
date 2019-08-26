//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>, StorageRemoveOperation {
    
    let request: AWSS3StorageRemoveRequest
    let service: AWSS3StorageServiceBehaviour
    let onComplete: ((CompletionEvent<StorageRemoveResult, StorageRemoveError>) -> Void)?
    
    init(_ request: AWSS3StorageRemoveRequest,
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
            switch(event) {
            case .initiated:
                break
            case .inProcess:
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
