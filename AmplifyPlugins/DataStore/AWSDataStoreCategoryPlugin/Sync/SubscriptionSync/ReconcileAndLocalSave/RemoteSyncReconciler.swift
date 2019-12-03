//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Reconciles incoming sync mutations with the state of the local store, and mutation queue.
@available(iOS 13.0, *)
struct RemoteSyncReconciler {
    typealias LocalModel = ReconcileAndLocalSaveOperation.LocalModel
    typealias RemoteModel = ReconcileAndLocalSaveOperation.RemoteModel
    typealias SavedModel = ReconcileAndLocalSaveOperation.AppliedModel

    enum Disposition {
        case applyRemoteModel(RemoteModel)
        case dropRemoteModel
        case error(DataStoreError)
    }

    static func reconcile(remoteModel: RemoteModel,
                          to localModel: LocalModel?,
                          storageAdapter: StorageEngineAdapter) -> Disposition {

        let pendingMutations: [MutationEvent]
        switch getPendingMutations(forModelId: remoteModel.model.id, storageAdapter: storageAdapter) {
        case .failure(let dataStoreError):
            return .error(dataStoreError)
        case .success(let mutationEvents):
            pendingMutations = mutationEvents
        }

        return disposition(for: remoteModel,
                           localModel: localModel,
                           pendingMutations: pendingMutations)
    }

    private static func getPendingMutations(forModelId modelId: Model.Identifier,
                                            storageAdapter: StorageEngineAdapter) -> DataStoreResult<[MutationEvent]> {
        let semaphore = DispatchSemaphore(value: 1)
        var pendingMutationResultFromQuery: DataStoreResult<[MutationEvent]>?
        MutationEvent.pendingMutationEvents(forModelId: modelId,
                                            storageAdapter: storageAdapter) {
                                                pendingMutationResultFromQuery = $0
                                                semaphore.signal()
        }
        semaphore.wait()

        guard let pendingMutationResult = pendingMutationResultFromQuery else {
            let dataStoreError = DataStoreError.unknown("Unable to query pending mutation events",
                                                        AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
            return .failure(dataStoreError)
        }

        return pendingMutationResult
    }

    private static func disposition(for remoteModel: RemoteModel,
                                    localModel: LocalModel?,
                                    pendingMutations: [MutationEvent]) -> Disposition {

        guard pendingMutations.isEmpty else {
            return .dropRemoteModel
        }

        guard let localModel = localModel else {
            return .applyRemoteModel(remoteModel)
        }

        // Technically, we should never receive a subscription for a version we already have, but we'll be defensive
        // and make this check include the current version
        if remoteModel.syncMetadata.version >= localModel.syncMetadata.version {
            return .applyRemoteModel(remoteModel)
        }

        return .dropRemoteModel
    }

}
