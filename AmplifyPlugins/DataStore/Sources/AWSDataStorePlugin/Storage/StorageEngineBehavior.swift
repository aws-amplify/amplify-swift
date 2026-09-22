//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

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

/// - Note: `Sendable` because the sync engine and the plugin hold this across task boundaries.
protocol StorageEngineBehavior: AnyObject, ModelStorageBehavior, Sendable {

    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> { get }

    /// start remote sync, based on if sync is enabled and/or authentication is required
    func startSync() -> Result<SyncEngineInitResult, DataStoreError>
    func stopSync(completion: @escaping DataStoreCallback<Void>)
    func clear(completion: @escaping DataStoreCallback<Void>)

    /// expresses whether the conforming type is syncing from a remote source.
    var syncsFromRemote: Bool { get }
}
