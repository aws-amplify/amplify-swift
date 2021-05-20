//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Reconciles incoming sync mutations with the state of the local store, and mutation queue.
@available(iOS 13.0, *)
struct RemoteSyncReconciler {
    typealias LocalMetadata = ReconcileAndLocalSaveOperation.LocalMetadata
    typealias RemoteModel = ReconcileAndLocalSaveOperation.RemoteModel

    enum Disposition {
        case create(RemoteModel)
        case update(RemoteModel)
        case delete(RemoteModel)
    }

    /// Reconciles the incoming `remoteModels` against the pending mutations.
    /// If there is a matching pending mutation, drop the remote model.
    ///
    /// - Parameters:
    ///   - remoteModels: models retrieved from the remote store
    ///   - pendingMutations: pending mutations from the outbox
    /// - Returns: remote models to be applied
    static func reconcile(_ remoteModels: [RemoteModel],
                          pendingMutations: [MutationEvent]) -> [RemoteModel] {
        guard !pendingMutations.isEmpty else {
            return remoteModels
        }

        let pendingMutationModelIdsArr = pendingMutations.map { mutationEvent in
            mutationEvent.modelId
        }
        let pendingMutationModelIds = Set(pendingMutationModelIdsArr)

        return remoteModels.filter { remoteModel in
            !pendingMutationModelIds.contains(remoteModel.model.id)
        }
    }

    /// Reconciles the incoming `remoteModels` against the local metadata.

    ///
    /// - Parameters:
    ///   - remoteModels: models retrieved from the remote store
    ///   - localMetadatas: metadata retrieved from the local store
    /// - Returns: disposition of models to apply locally
    static func reconcile(_ remoteModels: [RemoteModel],
                          localMetadatas: [LocalMetadata]) -> [Disposition] {
        var dispositions = [Disposition]()

        guard !remoteModels.isEmpty else {
            return dispositions
        }

        guard !localMetadatas.isEmpty else {
            remoteModels.forEach { remoteModel in
                if let disposition = reconcile(remoteModel, localMetadata: nil) {
                    dispositions.append(disposition)
                }
            }
            return dispositions
        }

        var localMetadataMap = [Model.Identifier: LocalMetadata]()
        for localMetadata in localMetadatas {
            localMetadataMap.updateValue(localMetadata, forKey: localMetadata.id)
        }

        remoteModels.forEach { remoteModel in
            if let disposition = reconcile(remoteModel, localMetadata: localMetadataMap[remoteModel.model.id]) {
                dispositions.append(disposition)
            }
        }

        return dispositions
    }

    /// Reconcile a remote model against local metadata
    /// If there is no local metadata for the corresponding remote model, and the remote model is not deleted, apply a
    /// `.create` disposition
    /// If there is no local metadata for the corresponding remote model, and the remote model is deleted, drop it
    /// If there is local metadata for the corresponding remote model, and the remote model is not deleted, apply an
    /// `.update` disposition
    /// if there is local metadata for the corresponding remote model, and the remote model is deleted, apply a
    /// `.delete` disposition
    ///
    /// - Parameters:
    ///   - remoteModel: model retrieved from the remote store
    ///   - localMetadata: metadata corresponding to the remote model
    /// - Returns: disposition of the model, `nil` if to be dropped
    static func reconcile(_ remoteModel: RemoteModel, localMetadata: LocalMetadata?) -> Disposition? {
        guard let localMetadata = localMetadata else {
            if !remoteModel.syncMetadata.deleted {
                return .create(remoteModel)
            }
            return nil
        }

        if remoteModel.syncMetadata.version >= localMetadata.version {
            if remoteModel.syncMetadata.deleted {
                return .delete(remoteModel)
            } else {
                return .update(remoteModel)
            }
        }
        return nil
    }
}
