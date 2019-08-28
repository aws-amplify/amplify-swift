//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@testable import AWSS3StoragePlugin

public class MockAWSS3StorageService: AWSS3StorageServiceBehaviour {

    private(set) public var executeGetRequestCalled: Bool?
    private(set) public var executeGetUrlRequestCalled: Bool?
    private(set) public var executePutRequestCalled: Bool?
    private(set) public var executeListRequestCalled: Bool?
    private(set) public var executeRemoveRequestCalled: Bool?

    public func execute(_ request: AWSS3StorageGetRequest, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void) {

        executeGetRequestCalled = true

        onEvent(StorageEvent.inProcess(Progress()))
        onEvent(StorageEvent.completed(StorageGetResult()))
    }

    public func execute(_ request: AWSS3StorageGetUrlRequest, onEvent:
        @escaping (StorageEvent<Void, Void, StorageGetUrlResult, StorageGetUrlError>) -> Void) {

        executeGetUrlRequestCalled = true
    }

    public func execute(_ request: AWSS3StoragePutRequest, onEvent:
        @escaping (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void) {

        executePutRequestCalled = true
    }

    public func execute(_ request: AWSS3StorageListRequest, onEvent:
        @escaping (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void) {

        executeListRequestCalled = true

        onEvent(StorageEvent.completed(StorageListResult(keys: ["list"])))
    }

    public func execute(_ request: AWSS3StorageRemoveRequest, onEvent:
        @escaping (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void) {
        executeRemoveRequestCalled = true
    }

}
