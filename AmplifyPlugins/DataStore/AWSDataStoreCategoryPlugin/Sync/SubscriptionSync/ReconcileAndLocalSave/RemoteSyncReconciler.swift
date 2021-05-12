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

    struct Disposition {
        var createModels = [RemoteModel]()
        var updateModels = [RemoteModel]()
        var deleteModels = [RemoteModel]()

        var totalCount: Int {
            createModels.count + updateModels.count + deleteModels.count
        }
    }

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

    static func reconcile(remoteModels: [RemoteModel],
                          localMetadatas: [LocalMetadata]) -> Disposition {
        var disposition = Disposition()

        guard !remoteModels.isEmpty else {
            return disposition
        }

        guard !localMetadatas.isEmpty else {
            remoteModels.forEach { remoteModel in
                if !remoteModel.syncMetadata.deleted {
                    disposition.createModels.append(remoteModel)
                }
            }
            return disposition
        }

        var localMetadataMap = [Model.Identifier: LocalMetadata]()
        for localMetadata in localMetadatas {
            localMetadataMap.updateValue(localMetadata, forKey: localMetadata.id)
        }

        remoteModels.forEach { remoteModel in
            guard let localMetadata = localMetadataMap[remoteModel.model.id] else {
                if !remoteModel.syncMetadata.deleted {
                    disposition.createModels.append(remoteModel)
                }
                return
            }

            if remoteModel.syncMetadata.version >= localMetadata.version {
                if remoteModel.syncMetadata.deleted {
                    disposition.deleteModels.append(remoteModel)
                } else {
                    disposition.updateModels.append(remoteModel)
                }
            }
        }

        return disposition

    }
}
