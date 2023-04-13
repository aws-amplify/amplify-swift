//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Combine

enum StorageEngineEvent {
    case started
    case mutationEvent(MutationEvent)
    case modelSyncedEvent(ModelSyncedEvent)
    case syncQueriesReadyEvent
    case readyEvent
}

enum SyncEngineInitResult {
    case alreadyInitialized
    case successfullyInitialized
    case failure(DataStoreError)
}

protocol StorageEngineBehavior: AnyObject, ModelStorageBehavior {

    @available(iOS 13.0, *)
    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> { get }

    /// start remote sync, based on if sync is enabled and/or authentication is required
    func startSync() -> Result<SyncEngineInitResult, DataStoreError>
    func stopSync(completion: @escaping DataStoreCallback<Void>)
    func clear(completion: @escaping DataStoreCallback<Void>)
}
