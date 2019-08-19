//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public class AWSS3StorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>, StorageGetOperation {
    
    var key: String
    
    var refGetTask: AWSS3TransferUtilityDownloadTask?
    var onEvent: ((AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void)?
    init(key: String) {
        self.key = key
        super.init(categoryType: .storage)
    }
    
    // implements Resumable
    public func pause() {
        self.refGetTask?.suspend()
    }
    
    // implements Resumbable
    public func resume() {
        self.refGetTask?.resume()
    }
    
    // override AmplifyOperation : Cancellable
    override public func cancel() {
        self.refGetTask?.cancel()
        cancel()
    }
    
    func emitEvent(progress: Progress) {
        self.onEvent?(AsyncEvent.inProcess(progress))
    }
    
    func emitSuccess(data: Data) {
        let result = StorageGetResult(data: data)
        self.onEvent?(AsyncEvent.completed(result))
    }
    
    override public func main() {
        
    }
}
