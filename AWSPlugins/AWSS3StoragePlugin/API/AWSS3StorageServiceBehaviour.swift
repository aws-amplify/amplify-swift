//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public protocol AWSS3StorageServiceBehaviour {
    
    func execute(_ request: AWSS3StorageGetRequest,
                 onEvent: @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void)
    
    func execute(_ request: AWSS3StorageGetUrlRequest,
                 onEvent: @escaping (StorageEvent<Void, Void, StorageGetUrlResult, StorageGetUrlError>) -> Void)
    
    func execute(_ request: AWSS3StoragePutRequest,
                 onEvent: @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void)
    
    func execute(_ request: AWSS3StorageListRequest, onEvent: @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void)
    
    func execute(_ request: AWSS3StorageRemoveRequest, onEvent: @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void)
}

