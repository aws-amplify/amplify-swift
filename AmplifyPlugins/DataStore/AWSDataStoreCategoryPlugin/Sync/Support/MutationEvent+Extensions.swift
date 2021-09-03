//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Dispatch
import AWSPluginsCore

extension MutationEvent {

    // Updates the head of pending mutation event queue for a given model `id`
    // if it has a `nil` version, with syncMetadata version in `mutationSync`
    // and saves it in the mutation event table
    static func updatePendingMutationEventVersionIfNil(for modelId: Model.Identifier,
                                                       mutationSync: MutationSync<AnyModel>,
                                                       storageAdapter: StorageEngineAdapter,
                                                       completion: @escaping DataStoreCallback<Void>) {
        MutationEvent.pendingMutationEvents(
            for: modelId,
            storageAdapter: storageAdapter) { queryResult in
            switch queryResult {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let localMutationEvents):
                guard var existingEvent = localMutationEvents.first else {
                    completion(.success(()))
                    return
                }

                if existingEvent.version == nil {
                    Amplify.log.verbose("""
                        Replacing existing mutation event having nil version with version from mutation response
                            \(mutationSync.syncMetadata.version)
                        """)
                    existingEvent.version = mutationSync.syncMetadata.version
                    storageAdapter.save(existingEvent, condition: nil) { result in
                        switch result {
                        case .failure(let dataStoreError):
                            completion(.failure(dataStoreError))
                        case .success:
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

}
