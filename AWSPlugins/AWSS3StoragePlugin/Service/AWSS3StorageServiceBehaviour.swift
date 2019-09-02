//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

protocol AWSS3StorageServiceBehaviour {

    func execute(_ request: AWSS3StorageGetRequest, identity: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void)

    func execute(_ request: AWSS3StorageGetUrlRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageGetUrlResult, StorageGetUrlError>) -> Void)

    func execute(_ request: AWSS3StoragePutRequest, identity: String, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void)

    func execute(_ request: AWSS3StorageListRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void)

    func execute(_ request: AWSS3StorageRemoveRequest, identity: String, onEvent:
        @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void)
}
