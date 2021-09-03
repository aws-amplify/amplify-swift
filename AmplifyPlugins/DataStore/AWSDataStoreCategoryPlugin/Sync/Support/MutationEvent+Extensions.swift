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

    // Updates the version of the head of pending mutation event queue for a given model `id`
    // with syncMetadata version in `mutationSync` and saves it in the mutation event table
    static func reconcilePendingMutationEventsVersion(mutationEvent: MutationEvent,
                                                      mutationSync: MutationSync<AnyModel>,
                                                      storageAdapter: StorageEngineAdapter,
                                                      completion: @escaping DataStoreCallback<Void>) {
        MutationEvent.pendingMutationEvents(
            for: mutationEvent.modelId,
            storageAdapter: storageAdapter) { queryResult in
            switch queryResult {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let localMutationEvents):
                guard var existingEvent = localMutationEvents.first else {
                    completion(.success(()))
                    return
                }

                // return if version of the pending mutation event is not nil and
                // is >= version contained in the response
                if existingEvent.version != nil && existingEvent.version! >= mutationSync.syncMetadata.version {
                    completion(.success(()))
                    return
                }

                do {
                    let responseModel = mutationSync.model.instance
                    let requestModel = try mutationEvent.decodeModel()

                    // check if the data sent in the request is the same as the response
                    // if it is, update the pending mutation event version to the response version
                    guard let modelSchema = ModelRegistry.modelSchema(from: mutationEvent.modelName),
                          modelSchema.isEqual(responseModel, requestModel) else {
                        completion(.success(()))
                        return
                    }

                    existingEvent.version = mutationSync.syncMetadata.version
                    storageAdapter.save(existingEvent, condition: nil) { result in
                        switch result {
                        case .failure(let dataStoreError):
                            completion(.failure(dataStoreError))
                        case .success:
                            completion(.success(()))
                        }
                    }
                } catch {
                    Amplify.log.verbose("Error decoding models: \(error)")
                    completion(.success(()))
                }
            }
        }
    }

}
